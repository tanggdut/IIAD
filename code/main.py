import sys
import os
import logging
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QApplication, QMainWindow, QPushButton, QWidget, QVBoxLayout, QLabel, QLineEdit, \
    QFileDialog, QMessageBox, QTextEdit, QSplitter, QHBoxLayout, QComboBox
from PyQt5.QtCore import QObject, pyqtSignal, QThread
import matlab.engine
from getROTI import calculate_roti  # Import functions from getROTI
import pandas as pd
import numpy as np
import xgboost as xgb
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
import joblib  # Used for saving and loading models
import re
from sklearn.metrics import confusion_matrix
import matplotlib.pyplot as plt
from PyQt5.QtGui import QPixmap

logging.basicConfig(filename='app.log', level=logging.INFO, format='%(asctime)s - %(message)s')

class Worker(QObject):
    """Background thread, used to run MATLAB functions"""
    finished = pyqtSignal()
    error = pyqtSignal(str)
    output = pyqtSignal(str)
    opt_params: dict
    def __init__(self, input_folder_o, input_folder_n, output_folder):
        super().__init__()
        self.input_folder_o = input_folder_o
        self.input_folder_n = input_folder_n
        self.output_folder = output_folder

    def run(self):
        try:
            # Start the MATLAB engine
            eng = matlab.engine.start_matlab()
            # Add the path where the MATLAB script is located
            eng.addpath(r"C:\path\to\your\matlab\scripts", nargout=0)

            # Calculate the value of pi
            pi_value = eng.eval('pi')

            # Construct the structure based on the input parameters
            opt = eng.struct(
                'gftype', self.opt_params['gftype'],
                'elmask', self.opt_params['elmask'] * pi_value / 180,
                'navsys', self.opt_params['navsys'],
                'gfslipthres', self.opt_params['gfslipthres'],
                'mwslipthres', self.opt_params['mwslipthres'],
                'hion', self.opt_params['hion']
            )


            # Get all the files in the input folder that start with any number and end with.o
            o_files = [os.path.join(self.input_folder_o, f) for f in os.listdir(self.input_folder_o) if
                       re.match(r'.*\.\d+o$', f)]
            n_files = [os.path.join(self.input_folder_n, f) for f in os.listdir(self.input_folder_n) if
                       re.match(r'.*\.\d+n$', f)]

            if not o_files:
                self.error.emit("No files ending the.o were found in the input folder.")
                return

            if not n_files:
                self.error.emit("No files ending the.n were found in the input folder.")
                return


            if not os.path.exists(self.output_folder):
                os.makedirs(self.output_folder)

            for o_file in o_files:
                for n_file in n_files:
                    file_name = os.path.basename(o_file)
                    # Construct the output file path
                    output_file = os.path.join(self.output_folder, file_name + '.tec')
                    # Call the MATLAB Functions
                    self.output.emit(f"Files being processed:{o_file} and {n_file}")
                    eng.getTEC(o_file, n_file, self.output_folder, opt, nargout=0)
                    self.output.emit(f"Files being processed:{o_file} and {n_file}")

            self.finished.emit()
        except Exception as e:
            self.error.emit(str(e))
        finally:
            if 'eng' in locals():
                eng.quit()

class ChildWindow1(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("getTEC")
        self.setGeometry(150, 150, 400, 500)  # Adjust the window size


        layout = QVBoxLayout()

        # Create labels and input boxes
        self.label1 = QLabel("Enter the folder (.o file):")
        self.input1 = QLineEdit()
        self.input1.setReadOnly(True)
        self.button1 = QPushButton("Browse")
        self.button1.clicked.connect(self.open_folder_dialog1)

        self.label2 = QLabel("Enter the folder (.n file):")
        self.input2 = QLineEdit()
        self.input2.setReadOnly(True)
        self.button2 = QPushButton("Browse")
        self.button2.clicked.connect(self.open_folder_dialog2)

        self.label3 = QLabel("Output path:")
        self.input3 = QLineEdit()
        self.input3.setReadOnly(True)
        self.button3 = QPushButton("Browse")
        self.button3.clicked.connect(self.save_folder_dialog)

        # Input box for adding opt parameters
        self.label_gftype = QLabel("gftype :")
        self.input_gftype = QLineEdit()
        self.input_gftype.setPlaceholderText("1")

        self.label_elmask = QLabel("elmask :")
        self.input_elmask = QLineEdit()
        self.input_elmask.setPlaceholderText("15")

        self.label_navsys = QLabel("navsys :")
        self.input_navsys = QLineEdit()
        self.input_navsys.setPlaceholderText("'G'")

        self.label_gfslipthres = QLabel("gfslipthres :")
        self.input_gfslipthres = QLineEdit()
        self.input_gfslipthres.setPlaceholderText("0.5")

        self.label_mwslipthres = QLabel("mwslipthres :")
        self.input_mwslipthres = QLineEdit()
        self.input_mwslipthres.setPlaceholderText("5")

        self.label_hion = QLabel("hion :")
        self.input_hion = QLineEdit()
        self.input_hion.setPlaceholderText("350000")

        self.label4 = QLabel("Running result:")
        self.result_label = QLabel("")

        self.info_output = QTextEdit()
        self.info_output.setReadOnly(True)

        self.run_button = QPushButton("Run")
        self.run_button.clicked.connect(self.run_matlab_code)

        # Add controls to the layout
        layout.addWidget(self.label1)
        layout.addWidget(self.input1)
        layout.addWidget(self.button1)

        layout.addWidget(self.label2)
        layout.addWidget(self.input2)
        layout.addWidget(self.button2)

        layout.addWidget(self.label3)
        layout.addWidget(self.input3)
        layout.addWidget(self.button3)

        layout.addWidget(self.label_gftype)
        layout.addWidget(self.input_gftype)

        layout.addWidget(self.label_elmask)
        layout.addWidget(self.input_elmask)

        layout.addWidget(self.label_navsys)
        layout.addWidget(self.input_navsys)

        layout.addWidget(self.label_gfslipthres)
        layout.addWidget(self.input_gfslipthres)

        layout.addWidget(self.label_mwslipthres)
        layout.addWidget(self.input_mwslipthres)

        layout.addWidget(self.label_hion)
        layout.addWidget(self.input_hion)

        layout.addWidget(self.label4)
        layout.addWidget(self.result_label)

        layout.addWidget(self.info_output)

        layout.addWidget(self.run_button)


        self.setLayout(layout)

    def open_folder_dialog1(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select the folder (.o file)")
        if folder_path:
            self.input1.setText(folder_path)

    def open_folder_dialog2(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select the folder (.n file)")
        if folder_path:
            self.input2.setText(folder_path)

    def save_folder_dialog(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select the output path")
        if folder_path:
            self.input3.setText(folder_path)

    def run_matlab_code(self):
        input_folder_o = self.input1.text()
        input_folder_n = self.input2.text()
        output_folder = self.input3.text()

        # Obtain the input value of the opt parameter
        gftype = int(self.input_gftype.text()) if self.input_gftype.text() else 1
        elmask = float(self.input_elmask.text()) if self.input_elmask.text() else 15
        navsys = self.input_navsys.text() if self.input_navsys.text() else 'G'
        gfslipthres = float(self.input_gfslipthres.text()) if self.input_gfslipthres.text() else 0.5
        mwslipthres = float(self.input_mwslipthres.text()) if self.input_mwslipthres.text() else 5
        hion = int(self.input_hion.text()) if self.input_hion.text() else 350000

        self.thread = QThread()
        self.worker = Worker(input_folder_o, input_folder_n, output_folder)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.finished.connect(self.thread.quit)
        self.worker.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.thread.deleteLater)
        self.worker.output.connect(self.info_output.append)
        self.worker.error.connect(self.handle_error)

        #  opt construction method
        self.worker.opt_params = {
            'gftype': gftype,
            'elmask': elmask,
            'navsys': navsys,
            'gfslipthres': gfslipthres,
            'mwslipthres': mwslipthres,
            'hion': hion
        }

        self.thread.start()

        self.run_button.setEnabled(False)
        self.thread.finished.connect(lambda: self.run_button.setEnabled(True))

    def handle_error(self, error):
        QMessageBox.warning(self, "Error", error)
        self.result_label.setText(f"Operation failed:{error}")
        logging.error(f"TEC generation failed: {error}")
class Worker2(QObject):
    """Background thread, used for running ROTI calculations"""
    finished = pyqtSignal()
    error = pyqtSignal(str)
    output = pyqtSignal(str)

    def __init__(self, input_file, output_folder, rot_interval=0.5, window_time=5):
        super().__init__()
        self.input_file = input_file
        self.output_folder = output_folder
        self.rot_interval = rot_interval
        self.window_time = window_time

    def run(self):
        try:
            # Call the ROTI calculation function and connect the output to the callback function
            calculate_roti(self.input_file, self.output_folder, self.rot_interval, self.window_time, callback=self.output.emit)
            self.finished.emit()
        except Exception as e:
            self.error.emit(str(e))
class ChildWindow2(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("getROTI")
        self.setGeometry(200, 200, 500, 400)


        layout = QVBoxLayout()

        # Create labels and input boxes
        self.label1 = QLabel("Input file (.tec file):")
        self.input1 = QLineEdit()
        self.input1.setReadOnly(True)
        self.button1 = QPushButton("Browse")
        self.button1.clicked.connect(self.open_file_dialog)

        self.label2 = QLabel("Output path:")
        self.input2 = QLineEdit()
        self.input2.setReadOnly(True)
        self.button2 = QPushButton("Browse")
        self.button2.clicked.connect(self.save_folder_dialog)

        # Time interval and sliding window time input boxes
        self.label_rot_interval = QLabel("rot-et:")
        self.input_rot_interval = QLineEdit()
        self.input_rot_interval.setPlaceholderText("The default is 0.5 minutes")
        self.input_rot_interval.setText("0.5")  # Set the default value

        self.label_window_time = QLabel("rot-wt:")
        self.input_window_time = QLineEdit()
        self.input_window_time.setPlaceholderText("The default is 5 minutes")
        self.input_window_time.setText("5")  # Set the default value

        self.label3 = QLabel("Running result:")
        self.result_label = QLabel("")

        self.info_output = QTextEdit()
        self.info_output.setReadOnly(True)

        self.run_button = QPushButton("Run")
        self.run_button.clicked.connect(self.run_roti_calculation)

        # Add the control to the layout
        layout.addWidget(self.label1)
        layout.addWidget(self.input1)
        layout.addWidget(self.button1)

        layout.addWidget(self.label2)
        layout.addWidget(self.input2)
        layout.addWidget(self.button2)

        layout.addWidget(self.label_rot_interval)
        layout.addWidget(self.input_rot_interval)

        layout.addWidget(self.label_window_time)
        layout.addWidget(self.input_window_time)

        layout.addWidget(self.label3)
        layout.addWidget(self.result_label)

        layout.addWidget(self.info_output)

        layout.addWidget(self.run_button)


        self.setLayout(layout)

    def open_file_dialog(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select the file", "", "TEC Files (*.tec)")
        if file_path:
            self.input1.setText(file_path)

    def save_folder_dialog(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select the output path")
        if folder_path:
            self.input2.setText(folder_path)

    def run_roti_calculation(self):
        input_file = self.input1.text()
        output_folder = self.input2.text()

        if not input_file:
            QMessageBox.warning(self, "Warning", "Please select an input file.")
            return

        if not output_folder:
            QMessageBox.warning(self, "Warning", "Please select an output path.")
            return

        # Obtain the time interval and the sliding window
        try:
            rot_interval = float(self.input_rot_interval.text())
            window_time = float(self.input_window_time.text())
        except ValueError:
            QMessageBox.warning(self, "Warning", "rot-et and rot-wt must be significant figures.")
            return

        # Ensure that the time interval is greater than 0
        if rot_interval <= 0 or window_time <= 0:
            QMessageBox.warning(self, "Warning", "rot-et and rot-wt must be greater than 0.")
            return

        self.thread = QThread()
        self.worker = Worker2(input_file, output_folder, rot_interval, window_time)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.finished.connect(self.thread.quit)
        self.worker.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.thread.deleteLater)
        self.worker.output.connect(self.info_output.append)
        self.worker.error.connect(self.handle_error)

        self.thread.start()

        self.run_button.setEnabled(False)
        self.thread.finished.connect(lambda: self.run_button.setEnabled(True))

    def handle_error(self, error):
        QMessageBox.warning(self, "Error", error)
        self.result_label.setText(f"Operation failed：{error}")
        logging.error(f"The ROTI calculation failed: {error}")

class Worker3(QObject):
    """Background thread, used for running model training"""
    finished = pyqtSignal()
    error = pyqtSignal(str)
    output = pyqtSignal(str)
    plot_confusion_matrix = pyqtSignal(np.ndarray, np.ndarray, str)

    def __init__(self, model_type, train_data_path, output_folder):
        super().__init__()
        self.model_type = model_type
        self.train_data_path = train_data_path
        self.output_folder = output_folder

    def run(self):
        try:
            import matplotlib
            matplotlib.use('agg')
            # Data preparation
            df_train = pd.read_excel(self.train_data_path, header=None)
            X = df_train.iloc[:, 0].values.reshape(-1, 1)  # Characteristics of the training set
            y = df_train.iloc[:, 1].values  # validation set

            # Divide the training set and the validation set
            split_index = 6443
            X_train, X_val = X[:split_index], X[split_index:]
            y_train, y_val = y[:split_index], y[split_index:]

            # Train the model
            if self.model_type == "XGBoost":
                params = {
                    'objective': 'reg:squarederror',
                    'max_depth': 3,
                    'eta': 0.1,
                    'subsample': 0.9,
                    'colsample_bytree': 1,
                }
                dtrain = xgb.DMatrix(X_train, label=y_train)
                model = xgb.train(params, dtrain, num_boost_round=500)
                joblib.dump(model, os.path.join(self.output_folder, 'xgboost_model.pkl'))
                self.output.emit("The XGBoost model training has been completed and saved!")

                # Calculate the predicted value of the validation set
                dval = xgb.DMatrix(X_val)
                y_pred_val = model.predict(dval)
                y_pred_val = np.round(y_pred_val).astype(int)

            elif self.model_type == "SVM":
                model = SVC(kernel='rbf')
                model.fit(X_train, y_train)
                joblib.dump(model, os.path.join(self.output_folder, 'svm_model.pkl'))
                self.output.emit("The SVM model training has been completed and saved！")

                # Calculate the predicted value of the validation set
                y_pred_val = model.predict(X_val)

            elif self.model_type == "RF":
                model = RandomForestClassifier(n_estimators=300, random_state=42, max_depth=None)
                model.fit(X_train, y_train)
                joblib.dump(model, os.path.join(self.output_folder, 'rf_model.pkl'))
                self.output.emit("The random forest model training has been completed and saved!")

                # Calculate the predicted value of the validation set
                y_pred_val = model.predict(X_val)

            else:
                raise ValueError("Unknown model type")
            plt.savefig(os.path.join(self.output_folder, f'{self.model_type.lower()}_confusion_matrix.png'))
            plt.close()
            # The main thread handles graphic generation
            self.plot_confusion_matrix.emit(y_val, y_pred_val, self.output_folder)

        except Exception as e:
            self.error.emit(str(e))
        finally:
            self.finished.emit()

class Worker4(QObject):
    """Background thread, used for detecting ionospheric irregularities in the ionosphere"""
    finished = pyqtSignal()
    error = pyqtSignal(str)
    output = pyqtSignal(str)

    def __init__(self, model_type, recognize_data_path, model_path, output_folder):
        super().__init__()
        self.model_type = model_type
        self.recognize_data_path = recognize_data_path
        self.model_path = model_path
        self.output_folder = output_folder
        self.model = None

    def run(self):
        try:
            # Read the data file to be detected
            df_recognize = self.read_excel_with_header(self.recognize_data_path)
            X_recognize = df_recognize.iloc[:, 5].values.reshape(-1, 1)  # Extract the 6th column (with index 5) as the feature

            # Loading model
            self.model = joblib.load(self.model_path)

            if self.model_type == "XGBoost":
                # For the XGBoost model, the data needs to be converted to the DMatrix format
                drecognize = xgb.DMatrix(X_recognize)
                y_pred = self.model.predict(drecognize)
            elif self.model_type == "SVM":
                # For the SVM model, the original feature data is directly used
                y_pred = self.model.predict(X_recognize)
            elif self.model_type == "RF":
                # For the random forest model, the original feature data is directly used
                y_pred = self.model.predict(X_recognize)
            else:
                raise ValueError("Unknown model type")

            # Make sure the prediction result is of integer type
            y_pred = np.round(y_pred).astype(int)

            self.output.emit(
                f"The detection is completed and the prediction results have been saved to: {self.output_folder}")

            # Save the prediction results and the corresponding time
            output_file = os.path.join(self.output_folder, f"{self.model_type.lower()}_prediction_results.txt")

            # Read date and time information
            # Convert the date in the first column from the format of 'YYYYMMDD' to datetime
            dates = pd.to_datetime(df_recognize.iloc[:, 0].astype(str), format='%Y%m%d')
            times = df_recognize.iloc[:, 1]  # The second column is the number of seconds in a day


            utc_times = dates + pd.to_timedelta(times, unit='seconds')

            # Include ROTI and tags in the saved txt file
            pd.DataFrame({
                'UTC': utc_times,
                'ROTI': df_recognize.iloc[:, 5],
                'Label': y_pred
            }).to_csv(output_file, sep='\t', index=False)

            # Visual prediction results
            self.visualize_predictions(y_pred, utc_times)

        except Exception as e:
            self.error.emit(str(e))
        finally:
            self.finished.emit()

    def read_excel_with_header(self, file_path):
        # Try to read the first row and check if it contains the table header
        try:

            df_preview = pd.read_excel(file_path, header=None, nrows=5)
            if df_preview.iloc[0].apply(lambda x: isinstance(x, str)).any():
                # If the first line contains a string, use it as the header of the table
                df_recognize = pd.read_excel(file_path, header=0)
                # Check if the column names contain 'ROTI' and find its index
                if 'ROTI' in df_recognize.columns:
                    roti_col_index = df_recognize.columns.get_loc('ROTI')
                    # Update the code that uses which column as the feature
                    X_recognize_col = roti_col_index
                else:

                    df_recognize = pd.read_excel(file_path, header=None)
                    X_recognize_col = 5
            else:
                df_recognize = pd.read_excel(file_path, header=None)
                X_recognize_col = 5
        except Exception as e:
            df_recognize = pd.read_excel(file_path, header=None)
            X_recognize_col = 5
            self.error.emit(f"Failed to detect header: {str(e)}")

        return df_recognize

    def clear_previous_model(self):
        # Clear the previous model cache or state
        if self.model:
            del self.model
        self.model = None

    def visualize_predictions(self, y_pred, utc_times):
        try:
            plt.switch_backend('agg')

            plt.figure(figsize=(18, 10))
            utc_times_list = utc_times.tolist()

            plt.plot(utc_times_list, y_pred, 'b-o', label='Predicted values')
            plt.title('Predicted Values')
            plt.xlabel('UTC Time')
            plt.ylabel('Predicted Values')
            plt.legend()
            plt.grid(True)

            import matplotlib.dates as mdates
            plt.gca().xaxis.set_major_locator(mdates.HourLocator(interval=1))
            plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))

            plot_path = os.path.join(self.output_folder, f'{self.model_type.lower()}_prediction_plot.png')
            plt.savefig(plot_path)
            plt.close()

            self.output.emit(f"The visualization of the prediction results has been saved to: {plot_path}")

        except Exception as e:
            self.error.emit(f"Visualization failure: {str(e)}")

class ChildWindow3(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Detection of ionospheric irregularities")
        self.setGeometry(200, 200, 800, 600)

        layout = QVBoxLayout()

        self.label1 = QLabel("Training data file:")
        self.input1 = QLineEdit()
        self.input1.setReadOnly(True)
        self.button1 = QPushButton("Browse")
        self.button1.clicked.connect(self.open_train_file_dialog)

        self.label2 = QLabel("Output path:")
        self.input2 = QLineEdit()
        self.input2.setReadOnly(True)
        self.button2 = QPushButton("Browse")
        self.button2.clicked.connect(self.save_folder_dialog)

        self.label3 = QLabel("Select the model:")
        self.model_combo = QComboBox()
        self.model_combo.addItems(["XGBoost", "SVM", "RF"])

        self.info_output = QTextEdit()
        self.info_output.setReadOnly(True)

        self.train_button = QPushButton("Train the model")
        self.train_button.clicked.connect(self.train_model)

        self.recognize_button = QPushButton("Detection")
        self.recognize_button.clicked.connect(self.recognize)

        self.label4 = QLabel("Data file to be detected:")
        self.input3 = QLineEdit()
        self.input3.setReadOnly(True)
        self.button3 = QPushButton("Browse")
        self.button3.clicked.connect(self.open_recognize_file_dialog)

        self.label5 = QLabel("Model file:")
        self.input4 = QLineEdit()
        self.input4.setReadOnly(True)
        self.button4 = QPushButton("Browse")
        self.button4.clicked.connect(self.open_model_file_dialog)

        self.image_layout = QHBoxLayout()
        self.cm_label = QLabel("Confusion matrix")
        self.cm_label.setAlignment(Qt.AlignCenter)
        self.cm_label.setFixedSize(350, 300)  # 设置固定大小
        self.prediction_label = QLabel("Detection results")
        self.prediction_label.setAlignment(Qt.AlignCenter)
        self.prediction_label.setFixedSize(350, 300)  # 设置固定大小
        self.image_layout.addWidget(self.cm_label)
        self.image_layout.addWidget(self.prediction_label)

        layout.addWidget(self.label1)
        layout.addWidget(self.input1)
        layout.addWidget(self.button1)

        layout.addWidget(self.label2)
        layout.addWidget(self.input2)
        layout.addWidget(self.button2)

        layout.addWidget(self.label4)
        layout.addWidget(self.input3)
        layout.addWidget(self.button3)

        layout.addWidget(self.label5)
        layout.addWidget(self.input4)
        layout.addWidget(self.button4)

        layout.addWidget(self.label3)
        layout.addWidget(self.model_combo)

        layout.addWidget(self.info_output)

        layout.addWidget(self.train_button)
        layout.addWidget(self.recognize_button)

        layout.addLayout(self.image_layout)

        self.setLayout(layout)

    def open_train_file_dialog(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select the training data file", "", "Excel Files (*.xlsx *.xls)")
        if file_path:
            self.input1.setText(file_path)

    def save_folder_dialog(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select the output path")
        if folder_path:
            self.input2.setText(folder_path)

    def open_recognize_file_dialog(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select the data file to be detected", "", "Excel Files (*.xlsx *.xls)")
        if file_path:
            self.input3.setText(file_path)

    def open_model_file_dialog(self):
        file_path, _ = QFileDialog.getOpenFileName(self, "Select the model file", "", "Model Files (*.pkl)")
        if file_path:
            self.input4.setText(file_path)
            self.clear_previous_model()

    def clear_previous_model(self):
        if hasattr(self, 'loaded_model'):
            del self.loaded_model
        self.loaded_model = None

    def train_model(self):
        self.cm_label.clear()
        self.cm_label.setText("Confusion matrix")
        self.prediction_label.clear()
        self.prediction_label.setText("Detection result")

        train_data_path = self.input1.text()
        output_folder = self.input2.text()
        model_type = self.model_combo.currentText()

        if not train_data_path or not output_folder:
            QMessageBox.warning(self, "Warning", "Please select the training data file and output path.")
            return

        self.thread = QThread()
        self.worker = Worker3(model_type, train_data_path, output_folder)
        self.worker.moveToThread(self.thread)

        self.worker.plot_confusion_matrix.connect(self.generate_confusion_matrix)

        self.thread.started.connect(self.worker.run)
        self.worker.finished.connect(self.thread.quit)
        self.worker.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.thread.deleteLater)
        self.worker.output.connect(self.info_output.append)
        self.worker.error.connect(self.handle_error)

        self.thread.start()

        self.train_button.setEnabled(False)
        self.thread.finished.connect(lambda: self.train_button.setEnabled(True))
        self.thread.finished.connect(lambda: self.recognize_button.setEnabled(True))
        self.thread.finished.connect(lambda: self.input3.setEnabled(True))
        self.thread.finished.connect(lambda: self.button3.setEnabled(True))
        self.thread.finished.connect(lambda: self.input4.setEnabled(True))
        self.thread.finished.connect(lambda: self.button4.setEnabled(True))

    def generate_confusion_matrix(self, y_true, y_pred, output_folder):
        try:
            # Calculate the confusion matrix
            cm = confusion_matrix(y_true, y_pred)
            total_samples = cm.sum()  # Calculate the total sample size
            cm_percent = cm / total_samples

            # Visualize the confusion matrix
            fig, ax = plt.subplots(figsize=(8, 6))
            im = ax.matshow(cm, cmap='Blues', alpha=0.8)

            fig.colorbar(im, ax=ax)

            # Set the axis label
            ax.set_xlabel('Predicted Class', fontsize=16)
            ax.set_ylabel('True Class', fontsize=16)
            ax.set_title('Confusion Matrix', fontsize=16)

            # Set the scale position and label
            ax.set_xticks(np.arange(cm.shape[1]))  # Set the scale position of the X-axis
            ax.set_yticks(np.arange(cm.shape[0]))  # Set the scale position on the Y-axis
            ax.set_xticklabels(['0', '1'],fontsize=14)  # Set the X-axis scale label
            ax.set_yticklabels(['0', '1'],fontsize=14)  # Set the Y-axis scale label

            ax.xaxis.set_ticks_position('bottom')
            ax.xaxis.set_label_position('bottom')

            for i in range(cm.shape[0]):
                for j in range(cm.shape[1]):
                    ax.text(j, i, f'{cm[i, j]}\n({cm_percent[i, j]:.2%})', ha='center', va='center', fontsize=14)

            plt.tight_layout()
            cm_path = os.path.join(output_folder, f'{self.model_combo.currentText().lower()}_confusion_matrix.tif')
            plt.savefig(cm_path)
            plt.close()

            self.info_output.append("The confusion matrix has been saved to the output folder")

            # Display the confusion matrix image
            self.show_confusion_matrix_image(output_folder)

        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to generate the confusion matrix：{str(e)}")
            self.info_output.append(f"Failed to generate the confusion matrix：{str(e)}")

        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to generate the confusion matrix：{str(e)}")
            self.info_output.append(f"Failed to generate the confusion matrix：{str(e)}")

    def show_confusion_matrix_image(self, output_folder):
        try:
            cm_path = os.path.join(output_folder, f'{self.model_combo.currentText().lower()}_confusion_matrix.tif')
            pixmap = QPixmap(cm_path)
            pixmap = pixmap.scaled(self.cm_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation)
            self.cm_label.setPixmap(pixmap)

        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to load the confusion matrix image:{str(e)}")
            self.info_output.append(f"Failed to load the confusion matrix image:{str(e)}")

    def recognize(self):
        self.prediction_label.clear()
        self.prediction_label.setText("Detection result")

        recognize_data_path = self.input3.text()
        model_path = self.input4.text()
        model_type = self.model_combo.currentText()

        if not recognize_data_path or not model_path:
            QMessageBox.warning(self, "Error", "Please select the data file and model file to be detected")
            return

        output_folder = os.path.dirname(model_path)

        self.thread = QThread()
        self.worker = Worker4(model_type, recognize_data_path, model_path, output_folder)
        self.worker.moveToThread(self.thread)

        self.thread.started.connect(self.worker.run)
        self.worker.finished.connect(self.thread.quit)
        self.worker.finished.connect(self.worker.deleteLater)
        self.thread.finished.connect(self.thread.deleteLater)
        self.worker.output.connect(self.info_output.append)
        self.worker.error.connect(self.handle_error)

        self.thread.start()

        self.recognize_button.setEnabled(False)
        self.thread.finished.connect(lambda: self.recognize_button.setEnabled(True))
        self.thread.finished.connect(lambda: self.show_recognition_result_image(output_folder))

    def show_recognition_result_image(self, output_folder):
        try:
            prediction_plot_path = os.path.join(output_folder,
                                                f'{self.model_combo.currentText().lower()}_prediction_plot.png')
            if os.path.exists(prediction_plot_path):
                pixmap = QPixmap(prediction_plot_path)
                pixmap = pixmap.scaled(self.prediction_label.size(), Qt.KeepAspectRatio, Qt.SmoothTransformation)
                self.prediction_label.setPixmap(pixmap)
            else:
                self.prediction_label.setText("The detection result picture was not found")

        except Exception as e:
            QMessageBox.warning(self, "Error", f"Failed to load the detection result image:{str(e)}")
            self.info_output.append(f"Failed to load the detection result image:{str(e)}")


    def handle_error(self, error):
        QMessageBox.warning(self, "Error", error)
        self.info_output.append(f"Detection failed：{error}")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Detection system for ionospheric irregularities")
        self.setGeometry(100, 100, 600, 300)

        # Create the content area of the main window
        main_widget = QWidget()
        self.setCentralWidget(main_widget)

        # Create the button layout
        button_layout = QVBoxLayout()

        # Create three buttons
        self.button1 = QPushButton("getTEC")
        self.button1.clicked.connect(self.open_child1)

        self.button2 = QPushButton("getROTI")
        self.button2.clicked.connect(self.open_child2)

        self.button3 = QPushButton("Detection")
        self.button3.clicked.connect(self.open_child3)

        button_layout.addWidget(self.button1)
        button_layout.addWidget(self.button2)
        button_layout.addWidget(self.button3)

        # Create a placeholder widget for button layout
        button_widget = QWidget()
        button_widget.setLayout(button_layout)
        button_widget.setStyleSheet("background-color: rgb(164, 163, 161);")  # Set the background color of the button layout area

        # Create an area for displaying the content of the sub-window
        self.content_area = QWidget()
        self.content_area_layout = QVBoxLayout(self.content_area)
        self.content_area_layout.setContentsMargins(0, 0, 0, 0)

        # Create a placeholder label for displaying the title of the sub-window area
        self.content_title = QLabel("Sub-window area")
        self.content_title.setAlignment(Qt.AlignCenter)
        self.content_area_layout.addWidget(self.content_title)

        # Create a divider to put the button layout and the content area together
        splitter = QSplitter(Qt.Horizontal)
        splitter.addWidget(button_widget)  # 添加按钮布局小部件
        splitter.addWidget(self.content_area)
        splitter.setSizes([150, 400])

        # Set the style of the dividing line
        splitter.setStyleSheet("""
            QSplitter::handle {
                background: rgb(200, 200, 200);
                width: 2px;
                border: 1px solid rgb(150, 150, 150);
            }
        """)

        main_layout = QHBoxLayout(main_widget)
        main_layout.addWidget(splitter)

    def clear_content_area(self):
        # Clear all the contents in the content_area layout
        while self.content_area_layout.count() > 0:
            item = self.content_area_layout.takeAt(0)
            widget = item.widget()
            if widget:
                widget.deleteLater()
    def open_child1(self):
        self.clear_content_area()  # Clear the previous interface
        self.child1 = ChildWindow1()
        self.content_area_layout.addWidget(self.child1)
        self.child1.show()

    def open_child2(self):
        self.clear_content_area()  # Clear the previous interface
        self.child2 = ChildWindow2()
        self.content_area_layout.addWidget(self.child2)
        self.child2.show()

    def open_child3(self):
        self.clear_content_area()  # Clear the previous interface
        self.child3 = ChildWindow3()
        self.content_area_layout.addWidget(self.child3)
        self.child3.show()


if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle('Fusion')
    main_window = MainWindow()
    main_window.show()
    sys.exit(app.exec_())