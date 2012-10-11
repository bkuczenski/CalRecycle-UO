function read_fac(fn,facYYYYread)% script file.  
% FACILITY_LIST_.txt created by a proper quoted-csv interpreter with s/,/_/g

global FACILITIES Facilities

if nargin<2
  facYYYYread={'','s','s','s','s','s','s','s',''};
% "counter"	
% "GEN_EPA_ID"	
% "FAC_NAME"	
% "FAC_STR1"	
% "FAC_CITY"	
% "FAC_CNTY"	
% "FAC_ST"	
% "FAC_ZIP"	
% "FAC_MAIL_STR1"
% ...
end

fac_filter=struct('Field',{'FAC_NAME','GEN_EPA_ID'},...
                    'Test',{@isempty,@FACILITY_lookup},...
                    'Pattern',{'',''},...%'^[A-Z]{2}[A-Z0-9][0-9]{9}$'},...
                    'Inv',{1,1});

LocalFac=read_dat(fn,',',facYYYYread,fac_filter);

if isempty(LocalFac)
  disp('Nothing to do.')
  return
end

fac_show={'s'};

show(LocalFac(1:24),fac_show);


Facilities=[Facilities LocalFac];
[FACILITIES,Ind]=sort({Facilities(:).GEN_EPA_ID});
Facilities=Facilities(Ind);
