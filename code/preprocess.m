function [ gf1,mw1,vs,csflag ] = preprocess( opt,obs,wave,el,gf0,mw0 )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function:  check data validity and detect cycle slip
% author:    Long Tang(Email:ltang@gdut.edu.cn)             
% input:     opt(struct), options
%            obs(struct), a single observation data 
%            wave, wavelength by function getfreqwave
%            el, satellite elevation (rad)
%            gf0, GF combination value at previous epoch
%            mw0, MW combination value at previous epoch
% output:    gf1, GF combination value at current epoch
%            mw1, mw combination value at current epoch
%            vs,  data validity (=1,yes; =0,no)
%            csflag, cycle slip occurred flag (=1,yes; =0, no)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vs=1;csflag=0;
ii=opt.gftype+1;
sat=obs.sat;

%check validity
if isnan(obs.P(1))||isnan(obs.P(ii))...
        ||isnan(obs.L(1))||isnan(obs.L(ii))
    vs=0;gf1=0;mw1=0;
    return;
end
if abs(obs.P(1)-obs.P(ii))>100||el<opt.elmask
    vs=0;gf1=0;mw1=0;
    return; 
end

%detect cycle slip by geometry free combination
gf1=wave(sat,1)*obs.L(1)-wave(sat,ii)*obs.L(ii);
if (gf0~=0 && abs(gf1-gf0)>opt.gfslipthres)
    vs=0;csflag=1;
end

%detect slip by Melbourne-Wubbena linear combination
mw1=wave(sat,1)*wave(sat,ii)*(obs.L(1)-obs.L(ii))/(wave(sat,ii)-wave(sat,1))-...
		(wave(sat,ii)*obs.P(1)+wave(sat,1)*obs.P(ii))/(wave(sat,ii)+wave(sat,1));
if (mw0~=0 && abs(mw1-mw0)>opt.mwslipthres)
    vs=0;csflag=1;
end   
end

