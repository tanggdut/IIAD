function [ rss] = satposg( obs,navdata )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  compute satellite position for GLO
% author:    Long Tang(Email:ltang@gdut.edu.cn)             
% input:    obs(struct), a single observation data 
%            navdata(struct), navigation data by function readnav    
% output:   rs(3,1),satellite position in ecef cooridnate (unit,m)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%constants
clight= 299792458.0;
omge_glo=7.292115E-5;
tstep=60;
maxdtoe_glo=1800;
omge=omge_glo;
%transmission time by satellite clock
if isnan(obs.P(1))
    rss=zeros(3,1);
    return;
else
    tr=obs.P(1)/clight;
end
tsv=obs.time-tr;

%search satellite ephemeris
in=0;
for i=1:navdata.inf_t.ngeph
    if obs.sat~=navdata.geph(i).sat
        continue;
    end
    tt=tsv-navdata.geph(i).toc;
    if abs(tt)<=maxdtoe_glo
        in=i;
        break;
    end
end
if in==0
%     disp(['No ephemeris for satellite:',obs.sat,'!!!']);
    rss=zeros(3,1);
    return;
end

%satellite clock bias
tt=tsv-navdata.geph(in).toc;
tt=tt-(-navdata.geph(in).clk(1)+navdata.geph(in).clk(2)*tt);
tt=tt-(-navdata.geph(in).clk(1)+navdata.geph(in).clk(2)*tt);
dtc=-navdata.geph(in).clk(1)+navdata.geph(in).clk(2)*tt;
tsv=tsv-dtc;  

%satellite position
toe=navdata.geph(in).toc;
x(1:3,1)=navdata.geph(in).pos;
x(4:6,1)=navdata.geph(in).vel;
acc=navdata.geph(in).acc;
tk=tsv-toe;
if tk<0 
    tt=-tstep; 
else
    tt=tstep;
end
while abs(tk)>1e-9
    tk=tk-tt;
    if abs(tk)<tstep
        tt=tk;
    end
    k1=gdeq(x,acc);w=x+k1*tt/2;
    k2=gdeq(w,acc);w=x+k2*tt/2;
    k3=gdeq(w,acc);w=x+k3*tt/2;
    k4=gdeq(w,acc);
    x=x+(k1+2*k2+2*k3+k4)*tt/6;
end
rs(1,1)=x(1);
rs(2,1)=x(2);
rs(3,1)=x(3);
%correciton for earh rotation
tt=tsv-obs.time;
rss(1,1)=cos(omge*tt)*rs(1,1)-sin(omge*tt)*rs(2,1);
rss(2,1)=sin(omge*tt)*rs(1,1)+cos(omge*tt)*rs(2,1);
rss(3,1)=rs(3,1);

end

