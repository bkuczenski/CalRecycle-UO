function D=facility_profile(MDfile,EPAID,generator)
% function D=facility(MDfile,regex)
% This function prepares a facility profile from a Tanner Report of Manifest
% data.  [new] Tanner Reports have nine fields: 
%  - Generator EPAID; 
%  - generator county;
%  - TSDF EPAID;
%  - TSDF county;
%  - Alt TSDF (always empty);
%  - Alt county (always empty);
%  - waste code;
%  - disposal method code;
%  - tons
%
% The function retrieves all records for which the TSDF field matches the regex.
% If the function is called with a nonzero third argument, the function retrieves
% all records for which the generator matches the regex.
%
% The function then aggregates the resulting records on waste code and disposal
% method (dropping the counterparty, either generator or TSDF).  It then cleans up
% the data by supplying translations of both waste code and disposal method, using
% reference data found in Tanner.mat

delim=',';
accum_cols='ddddmma';
fac_field=3;
if nargin>2 & ~isempty(generator)
  fac_field=1;
end
accum_cols(fac_field)='m';

try 
  fid=fopen(MDfile);
catch
  l=lasterr;
  disp(l)
  keyboard
end

switch length(regexp(fgetl(fid),delim,'split'))
  case 7
    manifest_read={'s','s','s','s','s','s','n'};
  case 9
    manifest_read={'s','s','s','s','','','s','s','n'};
  otherwise
    error(['Unhandled number of fields'])
end
fclose(fid)

D=read_dat(MDfile,delim,manifest_read,struct('Field',fac_field,...
                                                 'Test',@regexp,...
                                                 'Pattern',EPAID));
D=accum(D,accum_cols);

load Tanner

if isfield(D,'WASTE_STATE_CODE')
  D=vlookup(D,'WASTE_STATE_CODE',WasteCodes,'CAT_CODE','CAT_DESC');
elseif isfield(D,'CAT_CODE')
  D=vlookup(D,'CAT_CODE',WasteCodes,'CAT_CODE','CAT_DESC');
else
  disp('Which is the waste code?')
  keyboard
end
D=vlookup(D,'METH_CODE',Methods,'METH_CODE','METH_DESC');

D=orderfields(D,[1 2 6 3 7 4 5]);

