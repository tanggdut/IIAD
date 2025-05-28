function [ Pb ] = xyz2blh( P )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  cartesian coordinate to geodetic coordinate 
% author:    Long Tang(Email:ltang@gdut.edu.cn)     
% input:     P(X,Y,Z) in unit (m,m,m)
% output:    Pb(Lat,Lon,H)in unit (rad,rad,m)          
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%earth ellipsoid parameter (WGS-84)
a=6378137;%semi-major axis
f=1/298.257223563;%ellipticity
b=(1-f)*a;%semi-minor axis
e2=1-b^2/a^2;%The square of the eccentricity
r2=dot(P(1:2),P(1:2));
%compute lat and height by iteration
z=P(3);zk=0;
N=a;%radius of curvature in prime vertical
while(abs(z-zk)>1e-4)
    zk=z;
    sinp=z/sqrt(r2+z*z);
    N=a/sqrt(1.0-e2*sinp*sinp);
    z=P(3)+N*e2*sinp;
end
if r2>1e-12
    Lat=atan(z/sqrt(r2));
    Lon=atan2(P(2),P(1));
else
    if P(3)>0
        Lat=pi/2;
    else
        Lat=-pi/2;
    end
    Lon=0;
end
H=sqrt(r2+z*z)-N;
Pb=[Lat;Lon;H];
end

