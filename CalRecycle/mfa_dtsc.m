function Ta=mfa_dtsc(varargin)
% function Ta=mfa_dtsc(years)
% function Ta=mfa_dtsc(years,meths)
% function Ta=mfa_dtsc(years,meths,filename)
%
% Generate MFA summary numbers for reporting to DTSC.
%
% Activity levels are as follows (each quantity reported separately by waste
% code): 
% SOURCES
%  Generation in-state 
%  Import
%
% HANDLING
%  Transfer
%
% SINKS
%  Transfer Losses
%  Wastewater treatment (H135)
%  Hazardous Waste Disposal (H132)
%  Destructive Incineration (H040)
%  Other treatment or rejuvenation (H129)
%  DK process (H039)
%  Ev process (H039)
%  RFO, in-state mix -> to RFO, export, DK-balance (H039 + H050 + H061)
%  Export mix -> to RFO, non-Ev ReRe (H039 + H050 + H061)
%
% The default fate is RFO
%
% Facilities are described as (G)enerators, (C)onsolidators, (Tx)ransfer stations,
% or (P)rocessors, with respect to each waste code, based on their relative
% inflows and outflows (see md_node2 for details).  A facility which processes
% one waste code into another will manifest as a Processor for the incoming waste
% code and a Generator/Consolidator for the outgoing waste.  Because this waste is
% not properly "generated", it needs to be removed from the generation totals.
% This behavior is NOT intended to be auto-detected; it must be explicitly
% programmed.  (note: not yet implemented -- leads to slight overestimate for UO
% generation)
%
% This function uses ProcessInfo.csv to describe what a given facility does with the
% oil it processes.  The table includes columns for each fate except RFO/export,
% plus transfers between waste codes, and fractional amounts for each fate.  The
% remainder after all explicit fractions have been tabulated is sent to RFO,
% according to the facility's geography. 
%
% Transfers between waste codes are handled afterward, with inbound transfers to
% each waste code reducing the facility's reported generation in that waste code.
% Once facility generation is reduced to zero, the remaining amount in inbound
% transfer is re-destined to RFO.  If generation is not reduced fully to zero, the
% facility is assumed to properly generate some material.
%

%% ASSUMPTIONS
%% RFO: H050+H061 - average water content 5% -> wastewater
%% Wastewater: H135 - average oil content 5% -> RFO


global use_md2

if use_md2
  md_prefix='MD-Tn2_';
  md_node='MD-node2_';
else
  md_prefix='MD-Tn_';
  md_node='MD-node_';
end

years=varargin{1};
if nargin>1
  meths=varargin{2};
else
  meths={'H039','H040','H050','H061','H132','H135'};
end

if nargin>2
  filename=varargin{3};
else
  filename=['MFA-DTSC-check_' datestr(now,'YYYY-mmm-DD') '.xls'];
end

for i=1:length(years);

  yy=num2str(years(i));
  
  [~,Ti]=make_Tn(years(i),meths);

  if exist('T')
    for j=1:3
      T{j}=stack(T{j},Ti{j});
    end
  else
    T=Ti;
  end
end
  
for j=1:3
  T{j}=scalestruct(T{j},1.1022/301.85,{'WASTE_STATE_CODE','Year'});
%  T{j}=mvfield(T{j},'GenGAL','GenTONS');
  T{j}=mvfield(T{j},'DispGAL','DispTONS');
  
  T{j}=rmfield(T{j},'Class');
  
  T{j}=fieldop(T{j},'Collected','#DispTONS + #TxLosses - #Import');
  T{j}=mvfield(T{j},'WASTE_STATE_CODE','WC');
  T{j}=rmfield(T{j},{'GenGAL','TxIn','TxOut'});
  
  n=length(fieldnames(T{j}));
  T{j}=orderfields(T{j},[1 n 2:n-1]);
  
  Ta{j}=accum(T{j},['maaaadm' repmat('a',1,n-7)],'');
  Ta{j}=rmfield(Ta{j},'Count');
  % this is awkward
  fprintf('Loading manifest data as check')
  for i=1:length(years)
    load([md_node num2str(years(i)) '_22' num2str(j)]);
    %A=accum(MD.(['Q_' num2str(years(i)) '_22' num2str(j)]),'dddddda','');
    %Ta{j}(i).TannerTONS=A.GAL*1.1022/301.85;
    A=sum([MD.(['Q_' num2str(years(i)) '_22' num2str(j)]).GAL])*1.102/301.85;
  end
  Ta{j}=select(Ta{j},{'WC','Year','TannerTONS','Collected','Import','TxLosses',...
                      'DispTONS',meths{:},'OtherUnknown'});
  xlswrite(filename,struct2xls(Ta{j}),['Sheet' num2str(j)]);
end




%T=[Ti{1};Ti{2};Ti{3}];
%Ta=[Tia{1};Tia{2};Tia{3}];



