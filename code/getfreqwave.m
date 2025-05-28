function [ freq,wave ] = getfreqwave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  get the frequency and wavelength for each L band
% author:    Long Tang(Email:ltang@gdut.edu.cn)
% input:               
% output:    freq(unit,hz), signal frequency
%            wave(unit,m), signal wavelength    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%constants
clight=299792458.0;
maxprn=60;
freq=zeros(4*maxprn,3);
wave=zeros(4*maxprn,3);
glok = [1 -4 5 6 1 -4 5 6 -2 -7 0 -1 -2 -7 0 -1 4 -3 3 2 4 -3 3 2 0 0];

for i=1:4*maxprn
    if i<=maxprn                                                       %GPS
        freq(i,1) = 1575.42E6;    
        wave(i,1) = clight/freq(i,1);
        freq(i,2) = 1227.60E6;    
        wave(i,2) = clight/freq(i,2);
        freq(i,3) = 1176.45E6;    
        wave(i,3) = clight/freq(i,3);
    elseif i<=maxprn+26 &&i>maxprn                                     %GLO
        freq(i,1) = (1602 + 0.5625*glok(i-maxprn))*10^6;    
        wave(i,1) = clight/freq(i,1);
        freq(i,2) = (1246 + 0.4375*glok(i-maxprn))*10^6;    
        wave(i,2) = clight/freq(i,2);
        freq(i,3) = 1202.025*10^6;    
        wave(i,3) = clight/freq(i,3);
    elseif i<=3*maxprn && i>2*maxprn                                   %GAL
        freq(i,1) = 1575.42E6;    %E1
        wave(i,1) = clight/freq(i,1);
        freq(i,2) = 1207.14E6;    %E5b
        wave(i,2) = clight/freq(i,2);
        freq(i,3) = 1176.45E6;    %E5a
        wave(i,3) = clight/freq(i,3);
    elseif i> 3*maxprn                                                 %BDS
        freq(i,1) = 1561.098E6;    
        wave(i,1) = clight/freq(i,1);
        freq(i,2) = 1207.14E6;
        wave(i,2) = clight/freq(i,2);
        freq(i,3) = 1268.52E6;
        wave(i,3) = clight/freq(i,1);
    end
end

end

