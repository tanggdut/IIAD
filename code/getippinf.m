function [ippinf] = getippinf( obs,navdata,rr,stp,opt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  compute information of ionospheric pierce point
% author:    Long Tang(Email:ltang@gdut.edu.cn)             
% input:     obs(struct), a single observation data 
%            navdata(struct), navigation data by function readnav
%            rr(3,1), receiver position in blh coordinate
%            stp(3,1), receiver position in xyz coordinate
%            opt(struct), options
% output:    ippinf(1,5), project factor,latitude (rad),longitude (rad),
%            elevation(rad),azimuth (rad).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%constants
re_wgs84=6378137.0;
maxprn=60;
%satellite position
if obs.sat<=maxprn||obs.sat>2*maxprn
    svp=satpos(obs,navdata);
else
    svp=satposg(obs,navdata);
end
if norm(svp)<re_wgs84
    ippinf=zeros(1,5);
    return;
end
%xyz2enu
ds=svp-stp;
ss=norm(ds);
lat=rr(1);
lon=rr(2);
Bt=[-sin(lon)           cos(lon)                 0;
    -cos(lon)*sin(lat) -sin(lon)*sin(lat) cos(lat);
    cos(lon)*cos(lat)  sin(lon)*cos(lat) sin(lat)];
enu=Bt*ds;
%satellite azimuth and elevation
az=atan2(enu(1),enu(2));
az=mod(az,2*pi);
el=asin(enu(3)/ss);
%latitude, longitude, project factor in IPP
zen = asin(double(re_wgs84) * sin(pi/2 - double(el)) / (double(re_wgs84) + double(opt.hion)));
zen1=asin(re_wgs84*sin(0.9782*(pi/2-el))/(re_wgs84+506700));
pf=cos(zen1);	
pip=pi/2-el-zen;
plat=asin(sin(lat)*cos(pip)+cos(lat)*sin(pip)*cos(az));
plon=lon+asin(sin(pip)*sin(az)/cos(plat));

ippinf=[pf,plat,plon,el,az];
end

