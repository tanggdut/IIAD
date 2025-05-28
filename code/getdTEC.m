clear all;clc;
%.........................................................................%
%options
optd.mlen=121;                   %window length of Savitzky-Golay filter
optd.order=4;                    %polynomial order of Savitzky-Golay filter
optd.pcenter=[38.297 142.373];   %event center position in degree[lat,lon]
optd.fsat=[];                    %sat numbers ([] for all prns)
optd.hour=[5.5 7.5];             %time scope with unit hour
%file 
tecfile='E:\sample\Tohoku_earthquake\*.tec';
outpath='E:\sample\Tohoku_earthquake\';
%.........................................................................%
%check tec file
[tfpath,tname,ext]=fileparts(tecfile);
if ~isempty(tfpath)
    tfpath=[tfpath,'\'];
end
tname=[tname,ext];
file_tec=dir([tfpath,tname]);
ntf=length(file_tec);
if ntf==0
    error('No tec file !!!\n');
end
%compute ionospheric dTEC for each file (a combined file for all station is
%also generated.)
adtefile=[outpath,'allstation_prn15.dte'];
afid=fopen(adtefile,'w+');
for nsta=1:ntf
    disp(['->Processing station ',num2str(nsta)]);
    tecfile=[tfpath,file_tec(nsta).name];
    %read TEC file
    [~,fname,~]=fileparts(tecfile);
    [data1 data2 data3 data4 data5 data6 data7 data8]=textread(tecfile,...
    '%f%f%d%*s%d%*s%f%f%f%f','headerlines', 2); %#ok<REMFF1>
    tecdata=[data1 data2 data3 data4 data5 data6 data7 data8];
    dtefile=[outpath,fname,'.dte'];
    %generate dTEC file
    sgdTEC( optd,tecdata,dtefile,afid);
end
fclose(afid);
clear all;