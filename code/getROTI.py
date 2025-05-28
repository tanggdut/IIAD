import numpy as np
import pandas as pd
import os

def calculate_roti(input_file, output_folder, rot_interval=0.5, window_time=5, callback=None):
    # Data import, skip the name line at the beginning of the file
    columns = ['Date', 'Time', 'NSAT', 'Satellite', 'NSTA', 'NAME', 'STEC', 'MF', 'PLAT', 'PLON']
    df = pd.read_csv(input_file, sep='\s+', names=columns, skiprows=2, engine='python')

    df['Time'] = pd.to_numeric(df['Time'], errors='coerce')
    df['STEC'] = pd.to_numeric(df['STEC'], errors='coerce')
    df['MF'] = pd.to_numeric(df['MF'], errors='coerce')
    df['PLAT'] = pd.to_numeric(df['PLAT'], errors='coerce')
    df['PLON'] = pd.to_numeric(df['PLON'], errors='coerce')

    # Classified by satellite
    satellites = df['Satellite'].unique()
    roti_results = []

    for sat in satellites:
        sat_df = df[df['Satellite'] == sat].copy()
        sat_df = sat_df.sort_values(by='Time')
        sat_df.reset_index(drop=True, inplace=True)

        # Directly use the time interval specified by the user (unit: minutes)
        user_defined_time_diff = rot_interval

        # Calculate the ROT using the time interval specified by the user
        stec_diff = sat_df['STEC'].diff().fillna(0)
        rot = stec_diff / user_defined_time_diff
        rot.iloc[0] = np.nan  # The first value cannot calculate the difference and is set to NaN

        # Calculate the window_size based on the sampling rate and the sliding window time
        # The sampling rate is uniform, and the average of the time differences of the previous few times is used as the sampling rate
        time_diff = sat_df['Time'].diff().fillna(0) / 60.0  # Convert seconds into minutes
        sample_rate = time_diff[1:6].mean()  # Take the average of the first five time differences as the sampling rate
        if sample_rate == 0:
            window_size = 10  # Default value
        else:
            # Calculate how many sampling points are needed to cover the sliding window time
            window_size = int(window_time / sample_rate)
            window_size = max(2, window_size)  # Make sure the window size is at least 2

        for i in range(len(sat_df)):
            if i >= window_size:
                window_rot = rot[i - window_size + 1:i+1]
                rot_mean = window_rot.mean()
                rot_squared_mean = (window_rot ** 2).mean()
                roti = np.sqrt(rot_squared_mean - rot_mean ** 2)
                roti_results.append({
                    'Date': sat_df['Date'].iloc[i],
                    'Time': sat_df['Time'].iloc[i],
                    'Satellite': sat,
                    'Receiver': sat_df['Receiver'].iloc[i],
                    'ROT': rot[i],
                    'ROTI': roti,
                    'MF': sat_df['MF'].iloc[i],
                    'PLAT': sat_df['PLAT'].iloc[i],
                    'PLON': sat_df['PLON'].iloc[i]
                })

    # Create the result DataFrame
    roti_df = pd.DataFrame(roti_results)

    # Save the result to the.rot file
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    output_rot_file = os.path.join(output_folder, f'{base_name}.rot')
    with open(output_rot_file, 'w') as f:
        for _, row in roti_df.iterrows():
            f.write(f"{row['Date']}\t{row['Time']:.2f}\t{row['Satellite']}\t{row['NAME']}\t{row['ROT']:.6f}\t{row['ROTI']:.6f}\t{row['MF']}\t{row['PLAT']:.6f}\t{row['PLON']:.6f}\n")

    # Save the result to the.xlsx file
    output_xlsx_file = os.path.join(output_folder, f'{base_name}.xlsx')
    roti_df.to_excel(output_xlsx_file, index=False)

    if callback:
        callback(f"Results saved to {output_rot_file} and {output_xlsx_file}")