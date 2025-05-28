function [ obs] = setobstype(buff,codeprior,sys,otype,sta_t)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  set observation type
% author:    Long Tang(Email:ltang@gdut.edu.cn)
% input:     buff(char),   observation data line
%            codeprior(char),   prior code
%            sys(int), satellite system (1,GPS;2,GLO;3,Gal;4,BDS)
%            otype(char), observation type (such as 'C1','L1')
% output:    obs(double), observation data 
%        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
obs=NaN;
if sta_t.version>=3                                              %version 3
    for ip=1:length(codeprior)
         tyeindex=strfind(sta_t.obstype(sys).tye,strcat(otype,codeprior(ip)));
         if ~isempty(tyeindex)
             ntye=ceil(tyeindex/4);
             if length(buff)>(16*ntye)
                obs=str2double(buff(4+16*(ntye-1):16*ntye+1));
                if ~isnan(obs)
                    break;
                end
             end
         end
    end
else                                                             %version 2
    tyeindex=strfind(sta_t.obstype.tye,otype);
    if ~isempty(tyeindex)
        ntye=ceil(tyeindex/6);
         if length(buff)>(16*ntye-3)
             obs=str2double(buff(1+16*(ntye-1):16*ntye-2));
         end
    end
end

end


