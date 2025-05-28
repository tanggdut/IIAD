function [ navdata ] = readnav( navfile )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  read rinex navigation data file (rinex 2/3)
% author:    Long Tang(Email:ltang@gdut.edu.cn)
% input:     navfile (char),   observation file           
% output:    navdata (struct), navigation data, the reference time is GPS
%            time    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
t1=clock;
%constants and struct
maxprn=60;
eph=struct('toc',{},'sat',{},'clk',{},...   %GPS/GAL/BDS navigation message
              'iode',{},'crs',{},'deln',{},'m0',{},...
              'cuc',{},'e',{},'cus',{},'a',{},...
              'toes',{},'cic',{},'OMG0',{},'cis',{},...
              'i0',{},'crc',{},'omg',{},'OMGd',{},...
              'idot',{},'code',{},'week',{},'flag',{},...
              'sva',{},'svh',{},'tgd',{},'iodc',{},...
              'ttr',{},'fit',{},'toe',{});  
geph=struct('toc',{},'sat',{},'clk',{},'tof',{},... %GLO navigation message 
            'pos',{},'vel',{},'acc',{},'svh',{},'frq',{},...
            'age',{},'iode',{});

%open navfile
fid= fopen(navfile, 'r');
if (fid == -1)
    error('Open file named %s error!!\n', navfile);
end
buff = fgets(fid);
inf_t.version = str2double(buff(1:15));
if ~(strcmp(buff(21),'N'))
    error('File named %s is not navigation file!!\n', navfile);
end

disp(['  Reading navfile:',navfile,'...']);
%read rinex header
while(buff)
     buff=fgets(fid);
    if strfind(buff,'ION ALPHA')                                 %version 2
        inf_t.iongps(1:4)=cell2mat(textscan(buff(1:60),'%f%f%f%f'));
    elseif strfind(buff,'ION BETA')
        inf_t.iongps(5:8)=cell2mat(textscan(buff(1:60),'%f%f%f%f'));
    elseif strfind(buff,'DELTA-UTC: A0,A1,T,W')
        inf_t.utcgps=cell2mat(textscan(buff(1:60),'%f%f%f%f'));
    elseif strfind(buff,'IONOSPHERIC CORR')                      %version 3
        if strfind(buff,'GPSA') 
            inf_t.iongps(1:4)=cell2mat(textscan(buff(5:53),'%f%f%f%f'));
        elseif strfind(buff,'GPSB') 
            inf_t.iongps(5:8)=cell2mat(textscan(buff(5:53),'%f%f%f%f'));
        elseif strfind(buff,'GAL') 
             inf_t.iongal=cell2mat(textscan(buff(5:53),'%f%f%f'));
        elseif strfind(buff,'BDSA') 
            inf_t.ionbds(1:4)=cell2mat(textscan(buff(5:53),'%f%f%f%f'));
        elseif strfind(buff,'BDSB') 
             inf_t.ionbds(5:8)=cell2mat(textscan(buff(5:53),'%f%f%f%f'));
        end
    elseif strfind(buff,'TIME SYSTEM CORR')  
        if strfind(buff,'GPUT')
           inf_t.utcgps=cell2mat(textscan(buff(5:50),'%f%f%f%f'));
        elseif strfind(buff,'GLUT') 
            inf_t.utcglo=cell2mat(textscan(buff(5:50),'%f%f%f%f'));
        elseif strfind(buff,'GAUT') 
             inf_t.utcgal=cell2mat(textscan(buff(5:50),'%f%f%f%f'));
        elseif strfind(buff,'BDUT') 
             inf_t.utcbds=cell2mat(textscan(buff(5:50),'%f%f%f%f'));
        end
    elseif strfind(buff,'LEAP SECONDS') 
        inf_t.leaps=str2double(buff(1:6));
    elseif strfind(buff,'END OF HEADER')
        break;
    end
end

%read rinex body
inum=0;inumg=0;
while ~feof(fid)
    buff=fgets(fid);
    if inf_t.version>3                                           
        sat=sscanf(buff(2:3),'%d');
        eptime=sscanf(buff(4:23),'%d%d%d%d%d%f');
        sp=4;
        switch buff(1)
            case 'G'
                sysflag=0;
            case 'R'
                sat=sat+maxprn;sysflag=1;
            case 'E'
                sat=sat+maxprn*2;sysflag=0;
            case 'C'
                sat=sat+maxprn*3;sysflag=0;
            otherwise
                break;
        end
    else                                                  
        sat=sscanf(buff(1:2),'%d');
        sysflag=0;
        eptime=sscanf(buff(3:22),'%d%d%d%d%d%f');
        eptime(1)=eptime(1)+2000;
        sp=3;
    end
    eptime=eptime';
    if sysflag==0                                              %GPS/GAL/BDS
        inum=inum+1;
        eph(inum).sat=sat;
        eph(inum).toc=(datenum(eptime)-datenum(1980,1,6))*86400; 
        if sat>maxprn*3
           eph(inum).toc=eph(inum).toc+14; 
        end
        eph(inum).clk= cell2mat(textscan(buff(sp+20:end),'%f%f%f')); 
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-1
        eph(inum).iode=data(1);eph(inum).crs=data(2);
        eph(inum).deln=data(3);eph(inum).m0=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-2
        eph(inum).cuc=data(1);eph(inum).e=data(2);
        eph(inum).cus=data(3);eph(inum).a=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-3
        eph(inum).toes=data(1);eph(inum).cic=data(2);
        eph(inum).OMG0=data(3);eph(inum).cis=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-4
        eph(inum).i0=data(1);eph(inum).crc=data(2);
        eph(inum).omg=data(3);eph(inum).OMGd=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-5
        eph(inum).idot=data(1);eph(inum).code=data(2);
        eph(inum).week=data(3);
        if sat<maxprn
            eph(inum).flag=data(4);
        end
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-6
        eph(inum).sva=data(1);eph(inum).svh=data(2);
        eph(inum).tgd=data(3);
        if sat>maxprn*2
            eph(inum).tgd(2)=data(4);
        else
            eph(inum).iodc=data(4);
        end
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f'));            %orbit-7
        eph(inum).ttr=data(1);
        if sat<maxprn
            eph(inum).fit=data(2);
        elseif sat>maxprn*3
            eph(inum).iodc=data(2);
        end
        if sat>maxprn*3
            eph(inum).toe=eph(inum).toes+eph(inum).week*86400*7+ ... 
                (datenum(2006,1,1)-datenum(1980,1,6))*86400+14;
        else
            eph(inum).toe=eph(inum).toes+eph(inum).week*86400*7;
        end
        tt=eph(inum).toe-eph(inum).toc;
        if tt<-302400
            eph(inum).toe=eph(inum).toe+604800;
        elseif tt>302400
            eph(inum).toe=eph(inum).toe-604800;
        end
    else                                                               %GLO
        inumg=inumg+1;
        geph(inumg).sat=sat;
        geph(inumg).toc=(datenum(eptime)-datenum(1980,1,6))*86400+inf_t.leaps;
        geph(inumg).clk= cell2mat(textscan(buff(sp+20:sp+57),'%f%f'));
        geph(inumg).clk(1)=-geph(inumg).clk(1);
        geph(inumg).tof= cell2mat(textscan(buff(sp+58:end),'%f'));
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-1
        geph(inumg).pos(1)=data(1);geph(inumg).vel(1)=data(2);
        geph(inumg).acc(1)=data(3);geph(inumg).svh=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-2
        geph(inumg).pos(2)=data(1);geph(inumg).vel(2)=data(2);
        geph(inumg).acc(2)=data(3);geph(inumg).fre=data(4);
        buff=fgets(fid);  
        data=cell2mat(textscan(buff(sp+1:end),'%f%f%f%f'));        %orbit-3
        geph(inumg).pos(3)=data(1);geph(inumg).vel(3)=data(2);
        geph(inumg).acc(4)=data(3);geph(inumg).age=data(4);
        geph(inumg).pos=geph(inumg).pos*1e3;
        geph(inumg).vel=geph(inumg).vel*1e3;
        geph(inumg).acc=geph(inumg).acc*1e3;
    end
    
end
inf_t.neph=inum;inf_t.ngeph=inumg;
fclose(fid); 
navdata.inf_t=inf_t;
navdata.eph=eph;
navdata.geph=geph;

t2=clock;
t=etime(t2,t1);
disp(['   The navagation file read duration is ',num2str(t),'s.']);

end

