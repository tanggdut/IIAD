function ddmap( dtecfile,pcenter,latlim,lonlim,teclim,tsec)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  plot the two-dimention distribution of ionosphere dtec series
% author:   Long Tang(Email:ltang@gdut.edu.cn)   
% input:   dtecfile, dtec file
%          pcenter, [elat elon], point position,degree
%          latlim, [minlat maxlat],degree
%          lonlim, [minlon maxlon],degree
%          teclim, [bmin bmax], tecu
%          tsec, time in second
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%extract data
data=load(dtecfile);
x=data(:,7); %latitude
y=data(:,8); %longitude
z=data(:,5); %vertical dtec

%plot map
worldmap(latlim,lonlim);
load coast;
geoshow(lat, long,'color','k');
gridm('off');
%dtec in ipp
hold on;
scatterm(x,y,30,z,'.');
colormap(jet);
caxis([teclim(1) teclim(2)]);

%point center
linem(pcenter(1),pcenter(2) ,'marker','*','color','k','markersize',10);

% Create xlabel
% ylabel('Latitude');
% xlabel('Longitude');
hour=fix(tsec/3600);
minu=fix((tsec-hour*3600)/60);
secd=tsec-hour*3600-minu*60;
title([num2str(hour,'%02d'),':',num2str(minu,'%02d'),':', ... 
    num2str(secd,'%02d'),' UT'],'FontName','Arial','FontSize',12);

end
