function tdmap( dtecfile,xtt,ydd,btec )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  plot the time distance map of ionosphere dtec series
% author:   Long Tang(Email:ltang@gdut.edu.cn)   
% input:   dtecfile, dtec file
%          xtt, [xmin inter xmax], hour in a day
%          ydd, [ymin inter ymax], distance from point center
%          btec, [bmin inter bmax], color bar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%paramters
xtime=xtt(1):xtt(2):xtt(3);
ydist=ydd(1):ydd(2):ydd(3);
xbar=btec(1):btec(2):btec(3);
%extract data
data=load(dtecfile);
x=data(:,2)/3600; %s-->h
y=data(:,9); %km
z=data(:,5); %TECU

%plot map
% Create figure
figure1 = figure;
% Create axes
axes1 = axes('Parent',figure1,'XTick',xtime,'YTick',ydist);
xlim(axes1,[xtt(1) xtt(3)]);
ylim(axes1,[ydd(1) ydd(3)]);
hold(axes1,'on');
scatter(x,y,20,z,'.','Parent',axes1);
colormap(jet);
caxis([btec(1) btec(3)]);
h=colorbar('peer',axes1,'yTick',xbar);%,...
title(h,'TECU','FontName','Times New Roman','FontSize',10,'color','k');
% Create xlabel
xlabel(axes1,'UT (h)');
ylabel(axes1,'Point center distance (km)');
title(axes1,'Time-distance map');

end

