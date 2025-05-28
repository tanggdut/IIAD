function sgdTEC( optd,tecdata,dtefile,afid)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function: calculate dtec series using Savitzky-Golay smoothing filter
% author:   Long Tang(Email:ltang@gdut.edu.cn)             
% input:    optd(struct), options
%           tecdata(struct), tec data
%           dtefile,dtec file name    
%           afid,  file identifier 
%--tecdata line------------------------------------------------------------
% 1    2     3    4    5    6     7    8
% day  time  sat  sta  data mf  plat  plon
%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
flat=optd.pcenter(1);flon=optd.pcenter(2);
ft1=optd.hour(1);ft2=optd.hour(2);
order=optd.order;mlen=optd.mlen;
fsat=optd.fsat;
maxepd=300;                    % maximum epoch interval(s)
maxdiftec=1;                   % maximum difference TEC 
data=tecdata;
[ntal,~]=size(data);
fid=fopen(dtefile,'w+');
i=0;
for n=1:ntal
    i=i+1;
    if (i==1) 
        continue; 
    end
  %time and data
  tt=abs(abs(data(n,2)-data(n-1,2)));
  dt=abs(data(n,5)-data(n-1,5));
  sat1=data(n,3);sat2=data(n-1,3);
  %compute and output dtec
  if(~(tt<maxepd&&dt<maxdiftec&&sat1==sat2)||n==ntal)
     if(i>mlen*1.5)
       dtec=data(n-i+1:n-1,5)-sgolayfilt(data(n-i+1:n-1,5),order,mlen);
       dtec=dtec.*data(n-i+1:n-1,6);
     else
         i=1;
         continue;
     end
     for j=1:i-1
         %compute distance to point center
         x1=flat*pi/180;           y1=flon*pi/180;
         x2=data(n-i+j,7)*pi/180;y2=data(n-i+j,8)*pi/180;
         sd=6371*acos(sin(x1)*sin(x2)+cos(x1)*cos(x2)*cos(y1-y2));
         %output result
         if ((ismember(data(n-i+j,3),fsat)||(isempty(fsat))) ...
                 &&((data(n-i+j,2)>=ft1*3600)&&(data(n-i+j,2)<=ft2*3600)))
             %single file
             fprintf(fid,' %8d %8.1f%6d%6d%10.3f%9.3f%9.3f%9.3f%10.3f\n',... 
             data(n-i+j,1),data(n-i+j,2),data(n-i+j,3),data(n-i+j,4),dtec(j),... 
             data(n-i+j,6),data(n-i+j,7),data(n-i+j,8),sd);
             %combined file
             fprintf(afid,' %8d %8.1f%6d%6d%10.3f%9.3f%9.3f%9.3f%10.3f\n',... 
             data(n-i+j,1),data(n-i+j,2),data(n-i+j,3),data(n-i+j,4),dtec(j),... 
             data(n-i+j,6),data(n-i+j,7),data(n-i+j,8),sd);
         end
     end
%      disp(['Procesing ',num2str(data(n-1,4)),' station ',...
%          num2str(data(n-1,3)),' satellite...']);
     i=0;
  end  
end
fclose(fid);



