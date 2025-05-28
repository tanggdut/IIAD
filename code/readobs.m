function obsdata = readobs( obsfile,tsys )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  read rinex observation data file (rinex 2/3)
% author:    Long Tang(Email:ltang@gdut.edu.cn)
% input:     obsfile (char),   observation file
%            tsys (char),      satellite system ('G','R','E','C')
% output:    obsdata (struct), observation data
%        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t1=clock;
%constants and struct
maxprn=60;
obs=struct('ymd',{},'sec',{},'time',{},'sat',{},'P',{},'L',{},'D',{});
%open obsfile
fid= fopen(obsfile, 'r');
if (fid == -1)
    error('Open file named %s error!!\n', obsfile);
end
buff = fgets(fid);
sta_t.version = str2double(buff(1:15));
if ~(strcmp(buff(21),'O'))
    error('File named %s is not observation file!!\n', obsfile);
end

disp(['  Reading obsfile:',obsfile,'...']);
%read rinex header
a = 1;
while(buff)
    buff=fgets(fid);
    if strfind(buff,'MARKER NAME')
        sta_t.markername = strtrim(buff(1:60));
    elseif strfind(buff,'REC # / TYPE / VERS')
        sta_t.recid = strtrim(buff(1:20));
        sta_t.rectype = strtrim(buff(21:40));
        sta_t.recver = strtrim(buff(41:60));
    elseif strfind(buff,'ANT # / TYPE')
        sta_t.antid = strtrim(buff(1:20));
        sta_t.anttype = strtrim(buff(21:60));
    elseif strfind(buff,'APPROX POSITION XYZ')
        sta_t.pos = sscanf(buff(1:60),'%f',[1,3]);
    elseif strfind(buff,'ANTENNA: DELTA H/E/N')
        sta_t.antde = sscanf(buff(1:60),'%f',[1,3]);
    elseif strfind(buff,'SYS / # / OBS TYPES')                   %version 3
        satsys=buff(1);
        switch satsys
            case 'G'
                sta_t.obstype(1).nty=sscanf(buff(2:6),'%d');
                sta_t.obstype(1).tye=strtrim(buff(7:58));
                if sta_t.obstype(1).nty>13
                    buff=fgets(fid);
                    sta_t.obstype(1).tye=[sta_t.obstype(1).tye,' ',...
                        strtrim(buff(7:58))];
                end
           case 'R'
                sta_t.obstype(2).nty=sscanf(buff(2:6),'%d');
                sta_t.obstype(2).tye=strtrim(buff(7:58));
                if sta_t.obstype(2).nty>13
                    buff=fgets(fid);
                    sta_t.obstype(2).tye=[sta_t.obstype(2).tye,' ',...
                        strtrim(buff(7:58))];
                end
          case 'E'
                sta_t.obstype(3).nty=sscanf(buff(2:6),'%d');
                sta_t.obstype(3).tye=strtrim(buff(7:58));
                if sta_t.obstype(3).nty>13
                    buff=fgets(fid);
                    sta_t.obstype(3).tye=[sta_t.obstype(3).tye,' ',...
                        strtrim(buff(7:58))];
                end
          case 'C'
                sta_t.obstype(4).nty=sscanf(buff(2:6),'%d');
                sta_t.obstype(4).tye=strtrim(buff(7:58));
                if sta_t.obstype(4).nty>13
                    buff=fgets(fid);
                    sta_t.obstype(4).tye=[sta_t.obstype(4).tye,' ',...
                        strtrim(buff(7:58))];
                end
                
        end
    elseif strfind(buff,'# / TYPES OF OBSERV')                   %version 2
      if a
        a = 0;
        sta_t.obstype.nty=sscanf(buff(2:6),'%d');
        sta_t.obstype.tye=strtrim(buff(7:60));
      else
         obstype=strtrim(buff(7:60));
         if sta_t.obstype.nty>10
             sta_t.obstype.tye=[sta_t.obstype.tye,'   ',...
                        obstype];
         end
      end
    elseif strfind(buff,'LEAP SECONDS')
        sta_t.leaps=sscanf(buff(1:6),'%f');
    elseif strfind(buff,'INTERVAL')
        sta_t.inter=sscanf(buff(1:10),'%f');
    elseif strfind(buff,'END OF HEADER')
        break;
    end
end
%read rinex body
inum=0;
if sta_t.version>=3                                              %version 3
    while ~feof(fid)                                            
        buff=fgets(fid);
        eflag=sscanf(buff(32),'%d');
        if (eflag>1)
            eline=sscanf(buff(33:35),'%d');
            for ei=1:eline
                buff=fgets(fid);
            end
            continue
        end
        eptime=sscanf(buff(2:29),'%d%d%d%d%d%f');
        eptime=eptime';
        ymd=eptime(1)*10000+eptime(2)*100+eptime(3);
        sec=eptime(4)*3600+eptime(5)*60+eptime(6);
  
        nesat=sscanf(buff(33:35),'%d');
        for isat=1:nesat
            buff=fgets(fid);
            if ~ismember(buff(1),tsys)
                continue;
            end
            inum=inum+1;
            obs(inum).ymd=ymd;
            obs(inum).sec=sec;
            obs(inum).time=(datenum(eptime)-datenum(1980,1,6))*86400;
            sat=sscanf(buff(2:3),'%d');
            switch buff(1)
                case 'G'
                     obs(inum).sat=sat;
                     codeprior='PWCSLXYMND';
                     obs(inum).P(1)=setobstype(buff,codeprior,1,'C1',sta_t);
                     obs(inum).P(2)=setobstype(buff,codeprior,1,'C2',sta_t);
                     obs(inum).L(1)=setobstype(buff,codeprior,1,'L1',sta_t);
                     obs(inum).L(2)=setobstype(buff,codeprior,1,'L2',sta_t);
                     obs(inum).D(1)=setobstype(buff,codeprior,1,'D1',sta_t);
                     obs(inum).D(2)=setobstype(buff,codeprior,1,'D2',sta_t);
                     codeprior='IQX';
                     obs(inum).P(3)=setobstype(buff,codeprior,1,'C5',sta_t);
                     obs(inum).L(3)=setobstype(buff,codeprior,1,'L5',sta_t);
                     obs(inum).D(3)=setobstype(buff,codeprior,1,'D5',sta_t);
                case 'R'
                     obs(inum).sat=sat+maxprn;
                     codeprior='PC';
                     obs(inum).P(1)=setobstype(buff,codeprior,2,'C1',sta_t);
                     obs(inum).P(2)=setobstype(buff,codeprior,2,'C2',sta_t);
                     obs(inum).L(1)=setobstype(buff,codeprior,2,'L1',sta_t);
                     obs(inum).L(2)=setobstype(buff,codeprior,2,'L2',sta_t);
                     obs(inum).D(1)=setobstype(buff,codeprior,2,'D1',sta_t);
                     obs(inum).D(2)=setobstype(buff,codeprior,2,'D2',sta_t);
                     codeprior='IQX';
                     obs(inum).P(3)=setobstype(buff,codeprior,2,'C5',sta_t);
                     obs(inum).L(3)=setobstype(buff,codeprior,2,'L5',sta_t);
                     obs(inum).D(3)=setobstype(buff,codeprior,2,'D5',sta_t);
                case 'E'
                     obs(inum).sat=sat+maxprn*2;
                     codeprior='BCXAZ';
                     obs(inum).P(1)=setobstype(buff,codeprior,3,'C1',sta_t);
                     obs(inum).L(1)=setobstype(buff,codeprior,3,'L1',sta_t);
                     codeprior='IQX';
                     obs(inum).P(2)=setobstype(buff,codeprior,3,'C7',sta_t);
                     obs(inum).L(2)=setobstype(buff,codeprior,3,'L7',sta_t);
                     obs(inum).P(3)=setobstype(buff,codeprior,3,'C5',sta_t);
                     obs(inum).L(3)=setobstype(buff,codeprior,3,'L5',sta_t);
                case 'C'
                    obs(inum).sat=sat+maxprn*3;
                    codeprior='IQX';
                    obs(inum).P(1)=setobstype(buff,codeprior,4,'C2',sta_t);
                    obs(inum).L(1)=setobstype(buff,codeprior,4,'L2',sta_t);
                    obs(inum).P(2)=setobstype(buff,codeprior,4,'C7',sta_t);
                    obs(inum).L(2)=setobstype(buff,codeprior,4,'L7',sta_t);
                    obs(inum).P(3)=setobstype(buff,codeprior,4,'C6',sta_t);
                    obs(inum).L(3)=setobstype(buff,codeprior,4,'L6',sta_t);
            end
        end
    end
else                                                             %version 2 （版本2）

    while ~feof(fid)
        buff=fgets(fid);
        eflag=sscanf(buff(29),'%d');
        if (eflag>1)
            eline=sscanf(buff(30:32),'%d');
            for ei=1:eline
                buff=fgets(fid);
            end
            continue
        end
        eptime=sscanf(buff(1:26),'%d%d%d%d%d%f');
        eptime=eptime';
        eptime(1)=eptime(1)+2000;
        ymd=eptime(1)*10000+eptime(2)*100+eptime(3);
        sec=eptime(4)*3600+eptime(5)*60+eptime(6);
        nesat=sscanf(buff(30:32),'%d');
        if nesat<=12
            lesat=deblank(buff(33:end));
        elseif nesat<=24
            lesat1=deblank(buff(33:end));
            buff=fgets(fid);
            lesat=[lesat1,deblank(buff(33:end))];
        elseif nesat<=36
            lesat1=deblank(buff(33:end));
            buff=fgets(fid);
            lesat2=deblank(buff(33:end));
            buff=fgets(fid);
            lesat=[lesat1,lesat2,deblank(buff(33:end))];
        elseif nesat>36
            lesat1=deblank(buff(33:end));
            buff=fgets(fid);
            lesat2=deblank(buff(33:end));
            buff=fgets(fid);
            lesat3=deblank(buff(33:end));
            buff=fgets(fid);
            lesat=[lesat1,lesat2,lesat3,deblank(buff(33:end))];
        end
        for isat=1:nesat
            buff=fgets(fid);
            if ~(ismember(lesat(isat*3-2),tsys)||isspace(lesat(isat*3-2)))
                if sta_t.obstype.nty>5
                    buff=fgets(fid);
                end
                if sta_t.obstype.nty>10
                    buff=fgets(fid);
                end 
                if sta_t.obstype.nty>=20
                    buff=fgets(fid);
                end 
                continue; % 不是所选的卫星系统就进入下一颗卫星
            end
            inum=inum+1;
            obs(inum).ymd=ymd;
            obs(inum).sec=sec;
            obs(inum).time=(datenum(eptime)-datenum(1980,1,6))*86400;
            sat=sscanf(lesat(isat*3-1:isat*3),'%d');
            switch lesat(isat*3-2)
                case 'R'
                    obs(inum).sat=sat+maxprn;
                case 'E'
                    obs(inum).sat=sat+maxprn*2;
                case 'C'
                    obs(inum).sat=sat+maxprn*3;
                otherwise
                    obs(inum).sat=sat;
            end
            if (sta_t.obstype.nty>5 & sta_t.obstype.nty<=10)
                buff1=fgets(fid);
                buff=deblank(buff);buff(80)='0';
                buff=strcat(buff,buff1);
            elseif (sta_t.obstype.nty>10 & sta_t.obstype.nty<20)
                buff1=fgets(fid);
                buff2=fgets(fid);
                buff=deblank(buff);buff(80)='0';
                buff1=deblank(buff1);buff1(80)='0';
                buff=strcat(buff,buff1);
                buff=strcat(buff,buff2);
            elseif (sta_t.obstype.nty>=20)
                buff1=fgets(fid);
                buff2=fgets(fid);
                buff3=fgets(fid);
                buff=deblank(buff);buff(80)='0';
                buff1=deblank(buff1);buff1(80)='0';
                buff2=deblank(buff2);buff2(80)='0';
                buff=strcat(buff,buff1);
                buff=strcat(buff,buff2);
                buff=strcat(buff,buff3);
            end
             obs(inum).P(1)=setobstype(buff,'','','P1',sta_t);
             if isnan(obs(inum).P(1))
                  obs(inum).P(1)=setobstype(buff,'','','C1',sta_t);
             end
             obs(inum).P(2)=setobstype(buff,'','','P2',sta_t);
             if isnan(obs(inum).P(2))
                  obs(inum).P(2)=setobstype(buff,'','','C2',sta_t);
             end
             obs(inum).P(3)=setobstype(buff,'','','P5',sta_t);
             if isnan(obs(inum).P(3))
                  obs(inum).P(3)=setobstype(buff,'','','C5',sta_t);
             end
             obs(inum).L(1)=setobstype(buff,'','','L1',sta_t);
             obs(inum).L(2)=setobstype(buff,'','','L2',sta_t);
             obs(inum).L(3)=setobstype(buff,'','','L5',sta_t);
             obs(inum).D(1)=setobstype(buff,'','','D1',sta_t);
             obs(inum).D(2)=setobstype(buff,'','','D2',sta_t);
        end
        
    end
  
   
end
sta_t.nobs=inum;
fclose(fid); 
%sort by sat number
[~,index]=sort([obs.sat]);
obs=obs(index);
obsdata.sta_t=sta_t;
obsdata.obs=obs;

t2=clock;
t=etime(t2,t1);
disp(['   The observation file read duration is ',num2str(t),'s.']);

end


