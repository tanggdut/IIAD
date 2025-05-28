clear all;close all;clc;
%.........................................................................%
%options
sp=30;                                %sample (s)
t0=(5*60+46)*60;                      %begin time (s)
dtt=4*sp;                             %time interval
pcenter=[38.297 142.373];             %[elat elon], point position,degree
latlim=[25 50];                       %[minlat maxlat],degree
lonlim=[125 155];                     %[minlon maxlon],degree
teclim=[-1 1];                        %[bmin bmax],tecu
%files
dtefile='E:\sample\Tohoku_earthquake\allstation.dte';
gifname='E:\sample\Tohoku_earthquake\2dmap.gif';
aviname='E:\sample\Tohoku_earthquake\2dmap.avi';
%.........................................................................%
figure;
set(gcf,'color','w'); 
xbar=teclim(1):teclim(2);
for i=1:500
    newfile=edtec(dtefile,0,[t0-0.1*sp+i*dtt t0+0.1*sp+i*dtt] );
    ss=dir(newfile);
    if ss.bytes==0
        break;
    end
    ddmap(newfile,pcenter,latlim,lonlim,teclim,t0+i*dtt);
    h=colorbar('FontName','Arial','FontSize',10);
    title(h,'TECU','FontName','Arial','FontSize',10,'color','k');
    img(i) = getframe(1);     %#ok<SAGROW>
    clf;
end
save 2dmv img
% gif
for idx = 1:size(img, 2)
    [A,map] = rgb2ind(frame2im(img(idx)),256);
    if idx == 1
        imwrite(A,map,gifname,'gif','LoopCount',Inf,'DelayTime',0.2);
    else
        imwrite(A,map,gifname,'gif','WriteMode','append','DelayTime',0.5);
    end
end
%avi
v = VideoWriter(aviname, 'Motion JPEG AVI'); 
v.FrameRate=5;
open(v);   
writeVideo(v, img);                  
close(v);                           

delete(newfile);
clear all;close all;
