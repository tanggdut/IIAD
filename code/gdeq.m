function [ xdot] = gdeq(x,acc)

%constants
mu_glo=3.9860044E14;
omge_glo=7.292115E-5;
re_glo=6378136.0;
j2_glo=1.0826257E-3;

r2=dot(x(1:3),x(1:3));
r3=r2*sqrt(r2);
omg2=omge_glo.^2;
if r2<=0
    xdot(1:6,1)=0;
    return;
end
a=1.5*j2_glo*mu_glo*re_glo.^2/r2/r3; 
b=5.0*x(3)*x(3)/r2;                    
c=-mu_glo/r3-a*(1.0-b);                
xdot(1:3,1)=x(4:6); 
xdot(4,1)=(c+omg2)*x(1)+2.0*omge_glo*x(5)+acc(1);
xdot(5,1)=(c+omg2)*x(2)-2.0*omge_glo*x(4)+acc(2);
xdot(6,1)=(c-2.0*a)*x(3)+acc(3);

end

