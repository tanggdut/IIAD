function [ newfile ] = edtec( oldfile,fsat,secd )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function: extract the dtec series for part satellites and epoches 
% author:   Long Tang(Email:ltang@gdut.edu.cn)   
% input:    oldfile, old dtec file
%           fsat[], sat numbers (0 for all prns)
%           secd (2,1), time scope with unit second
% output:   newfile, new dtec file
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
newfile=[oldfile,'n'];
data=load(oldfile);
nlen=length(data);
fid=fopen(newfile,'w+');
for i=1:nlen
    if((ismember(data(i,3),fsat)||(~fsat(1)))&&(data(i,2)>=secd(1)&&...
            data(i,2)<=secd(2)))
       fprintf(fid,' %8d %8.1f%6d%6d%10.3f%9.3f%9.3f%9.3f%10.3f\n',...
            data(i,1),data(i,2),data(i,3),data(i,4),data(i,5),data(i,6),...
            data(i,7),data(i,8),data(i,9));
    end
end
fclose(fid);
end

