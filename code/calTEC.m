function [  ] = calTEC( opt,obsdata,navdata,tecfile,nsta )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  compute ionospheric tec using CLL observation
% author:    Long Tang(Email:ltang@gdut.edu.cn)             
% input:     opt(struct), options
%            obsdata(struct), observation data
%            navdata(struct), navigation data
%            nsta, number of station
%            tecfile, output tec file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t1=clock;
%constants and structs
re_wgs84=6378137.0;
maxprn=60;
minarclen=80;
maxarclen=5000;
ippinft=zeros(maxarclen,5);
P4=zeros(maxarclen,1);
L4=zeros(maxarclen,1);
sec=zeros(maxarclen,1);
[ freq,wave ] = getfreqwave;

nobs=obsdata.sta_t.nobs;
name=obsdata.sta_t.markername;
obs=obsdata.obs;
stpos=obsdata.sta_t.pos';
a = norm(stpos)<=re_wgs84*0.8;
if norm(stpos)<=re_wgs84*0.8
    error('The position of station %s is error!!\n',obsdata.sta_t.markername);
end
rr=xyz2blh(stpos);

%compute and output tec file
disp(['  Computing TEC:',tecfile]);
fid=fopen(tecfile,'w+');
fprintf(fid,'%s\n','% Program:output the STEC in IPP (including satellite/receiver DCBs) unit/TECu');
fprintf(fid,'%s\n','%      DAY     SEC  NSAT   PRN  NSTA  NAME      STEC       MF     PLAT     PLON');
i=0;gf0=0;mw0=0;
for n=1:nobs
  ippinf=getippinf(obs(n),navdata,rr,stpos,opt);
  [gf1,mw1,vs,csflag]=preprocess( opt,obs(n),wave,ippinf(4),gf0,mw0);
  gf0=gf1;mw0=mw1;
  if vs==1
      i=i+1;
      ii=opt.gftype+1;
      sat=obs(n).sat;
      ymd=obs(n).ymd;
      sec(i)=obs(n).sec;
      P4(i)=obs(n).P(ii)-obs(n).P(1);
      L4(i)=obs(n).L(1)*wave(sat,1)-obs(n).L(ii)*wave(sat,ii);
      ippinft(i,:)=ippinf;
  end
  if vs==0||n==nobs
      if i>=minarclen
          N=L4-P4;
          N=sum(N(1:i))/i;
          for j=1:i
              ki=40.3*1e16*(freq(sat,1).^2-freq(sat,ii).^2)/...
                  (freq(sat,1).^2*freq(sat,ii).^2);
              stec=(L4(j)-N)/ki;
              mf=ippinft(j,1);
              plat=ippinft(j,2)*180/pi;
              plon=ippinft(j,3)*180/pi;
              if sat<=maxprn
                  prn=['G',num2str(sat,'%02d')];
              elseif sat<=2*maxprn
                  prn=['R',num2str(sat-maxprn,'%02d')];
              elseif sat<=3*maxprn
                  prn=['E',num2str(sat-2*maxprn,'%02d')];
              else
                  prn=['C',num2str(sat-3*maxprn,'%02d')];
              end
             fprintf(fid,'%10d%8.1f%6d%6s%6d%6s%10.3f%9.3f%9.3f%9.3f\n',... 
               ymd,sec(j),sat,prn,nsta,name,stec,mf,plat,plon);
          end
      end
      if csflag==1
          i=1;
          sec(1)=obs(n).sec;
          P4(1)=obs(n).P(ii)-obs(n).P(1);
          L4(1)=obs(n).L(1)*wave(sat,1)-obs(n).L(ii)*wave(sat,ii);
          ippinft(1,:)=ippinf;
      else
          i=0;
      end
  end
end
 
fclose(fid);

t2=clock;
t=etime(t2,t1);
disp(['   The tec file generation duration is ',num2str(t),'s.']);

end

