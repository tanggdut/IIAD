function [ rss] = satpos( obs,navdata)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  compute satellite position for GPS/GAL/BDS
% author:    Long Tang(Email:ltang@gdut.edu.cn)             
% input:    obs(struct), a single observation data 
%            navdata(struct), navigation data by function readnav    
% output:   rs(3,1),satellite position in ecef cooridnate (unit,m)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%constants
clight= 299792458.0;
mu_gps=3.9860050E14;
mu_gal=3.986004418E14;
mu_bds=3.986004418E14;
omge_gps=7.2921151467E-5;
omge_gal=7.2921151467E-5;
omge_bds=7.292115E-5;
maxdtoe_gps=7200;
maxdtoe_gal=3600;
maxdtoe_bds=21600;
maxprn=60;
if obs.sat<maxprn
    maxdtoe=maxdtoe_gps;mu=mu_gps;omge=omge_gps;
elseif obs.sat>2*maxprn&&obs.sat<=3*maxprn
    maxdtoe=maxdtoe_gal;mu=mu_gal;omge=omge_gal;
elseif obs.sat>3*maxprn
    maxdtoe=maxdtoe_bds;mu=mu_bds;omge=omge_bds;
end

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
for i=1:navdata.inf_t.neph
    if obs.sat~=navdata.eph(i).sat
        continue;
    end
    tt=tsv-navdata.eph(i).toe;
    if abs(tt)<=maxdtoe
        in=i;
        break;
    end
end
if in==0
%     disp(['No ephemeris for satellite:',num2str(obs.sat),'!!!']);
    rss=zeros(3,1);
    return;
end

%satellite clock bias
tt=tsv-navdata.eph(in).toc;
dtc=navdata.eph(in).clk(1)+navdata.eph(in).clk(2)*tt+ ...
    navdata.eph(in).clk(3)*tt*tt;
tsv=tsv-dtc;                                         

%satellite position
toe=navdata.eph(in).toe;toes=navdata.eph(in).toes;
a=navdata.eph(in).a;
m0=navdata.eph(in).m0;
deln=navdata.eph(in).deln;
e=navdata.eph(in).e;
omg=navdata.eph(in).omg; 
OMG0=navdata.eph(in).OMG0; OMGd=navdata.eph(in).OMGd;
i0=navdata.eph(in).i0; idot=navdata.eph(in).idot;
cus=navdata.eph(in).cus; cuc=navdata.eph(in).cuc;
crc=navdata.eph(in).crc; crs=navdata.eph(in).crs;
cic=navdata.eph(in).cic; cis=navdata.eph(in).cis;

tk=tsv-toe;
Mk=m0+(sqrt(mu)/(a*a*a)+deln)*tk;
Ek=Mk;dEk=1;
while dEk>1e-12
    E=Ek;
    Ek=Mk+e*sin(Ek);
    dEk=rem(abs(Ek-E),2*pi);
end
fk=atan2((sqrt(1-(e^2))*sin(Ek)),(cos(Ek)-e));
uk1=fk+omg;
uk=uk1+cuc*cos(2*uk1)+cus*sin(2*uk1);
rk=a*a*(1-e*cos(Ek))+crc*cos(2*uk1)+crs*sin(2*uk1);
ik=i0+idot*tk+cic*cos(2*uk1)+cis*sin(2*uk1);
xk=rk*cos(uk);yk=rk*sin(uk);
if obs.sat>3*maxprn&&obs.sat<=(3*maxprn+5)              %BDS GEO satellites
    Lk=OMG0+OMGd*tk-omge*toes;
    xg=xk*cos(Lk)-yk*cos(ik)*sin(Lk);
    yg=xk*sin(Lk)+yk*cos(ik)*cos(Lk);
    zg=yk*sin(ik);
    rs(1,1)=xg*cos(omge*tk)+yg*sin(omge*tk)*cos(-5*pi/180)+zg*sin(omge*tk)*sin(-5*pi/180);
    rs(2,1)=-xg*sin(omge*tk)+yg*cos(omge*tk)*cos(-5*pi/180)+zg*cos(omge*tk)*sin(-5*pi/180);
    rs(3,1)=-yg*sin(-5*pi/180)+zg*cos(-5*pi/180);
else
    Lk=OMG0+(OMGd-omge)*tk-omge*toes;
    rs(1,1)=xk*cos(Lk)-yk*cos(ik)*sin(Lk);
    rs(2,1)=xk*sin(Lk)+yk*cos(ik)*cos(Lk);
    rs(3,1)=yk*sin(ik);
end
%correciton for earh rotation
tt=tsv-obs.time;
rss(1,1)=cos(omge*tt)*rs(1,1)-sin(omge*tt)*rs(2,1);
rss(2,1)=sin(omge*tt)*rs(1,1)+cos(omge*tt)*rs(2,1);
rss(3,1)=rs(3,1);

end

