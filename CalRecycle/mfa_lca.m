function [Ti,Tia]=mfa_lca(varargin)
% function [D,chk]=mfa_lca(varargin)
%
% Generate Activity Levels for LCA model from MFA flows.  (oh, that's all.)
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

RFO_water_fraction=0.05;
WW_oil_fraction=0.05;

use_md2=true;

if use_md2
  md_prefix='MD-Tn2_';
else
  md_prefix='MD-Tn_';
end

if nargin==1
  year=varargin{1};
  load CRData
else
  CRData=varargin{1};
  year=varargin{2};
  if nargin>2
    % do argument parsing
    sel=varargin{3};
  end
end

yy=num2str(year);

[~,Ti]=make_Tn(year,{'H040','H050','H061','H129','H132','H135'});

for i=1:3
  % compute RFO fraction from H050, H061, H135
  Ti{i}=fieldop(Ti{i},'RFO',['floor(' num2str(1-RFO_water_fraction) ' * (#H050 + #H061) + ' ...
                       num2str(WW_oil_fraction) '* #H135)']);
  % compute Wastewater fraction from H050, H061, H135
  Ti{i}=fieldop(Ti{i},'Wastewater',['floor(' num2str(1-WW_oil_fraction) ' * #H135 + ' ...
                      num2str(RFO_water_fraction) ' * (#H050 + #H061) )']);
  Ti{i}=mvfield(Ti{i},'H040','Incin');
  Ti{i}=mvfield(Ti{i},'H129','Rejuv');
  Ti{i}=mvfield(Ti{i},'H132','HazWaste');
  Ti{i}=rmfield(Ti{i},{'H050','H061','H135'});
  [Ti{i}.DK]=deal(0);
  [Ti{i}.Ev]=deal(0);
end

% now process OtherUnknown according to ProcessInfo
fprintf(1,'%s','Reading Process Inventory Info: ')
PI=read_dat('ProcessInfo.csv',',',{'s','s','d'});

for i=1:3
  wc=['22' num2str(i)];
  for j=1:length(Ti{i})
    F=filter(PI,{'EPAID','WC'},{@strcmp},{Ti{i}(j).TSDF_EPA_ID,wc});
    if isempty(F)
      F=filter(PI,{'EPAID','WC'},{@strcmp},{'Default',wc});
    end
    RFO_frac=1-F.Wastewater-F.HazWaste-F.Incin-F.Rejuv-F.DK-F.Ev-F.To221-F.To222- ...
             F.To223;
    Disp=Ti{i}(j).OtherUnknown;
    if Disp~=0
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'Wastewater');
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'HazWaste');
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'Incin');
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'Rejuv');
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'DK');
      Ti{i}(j)=adjust(Ti{i}(j),Disp,F,'Ev');
      Ti{i}(j).RFO=Ti{i}(j).RFO+ceil(Disp*RFO_frac);
    end
  end
  [~,M]=filter(Ti{i},'Class',{@regexp},'.*-CA');
  [Ti{i}(M).RFO_CA]=Ti{i}(M).RFO;
  [Ti{i}(~M).RFO_CA]=deal(0);
  [Ti{i}(~M).ExportMix]=Ti{i}(~M).RFO;
  [Ti{i}(M).ExportMix]=deal(0);
  Ti{i}=rmfield(Ti{i},{'RFO','OtherUnknown'});
  Ti{i}=fieldop(Ti{i},'Collected','#DispGAL + #TxLosses - #Import');
  Ti{i}=mvfield(Ti{i},'Class','Facil');
  Ti{i}=mvfield(Ti{i},'WASTE_STATE_CODE','WC');
  
  Tia{i}=select(Ti{i},{'Year','WC','Facil','Collected','Import','TxIn','TxOut', ...
                      'TxLosses','DK','Ev','RFO_CA','ExportMix','Wastewater', ...
                      'HazWaste','Incin','Rejuv'}); 
  Tia{i}=accum(Tia{i},'mmmaaaaaaaaaaaaa','');
  Ti{i}=flookup(Ti{i},'TSDF_EPA_ID','FAC_NAME');
  Ti{i}=fieldop(Ti{i},'TxMeas','#TxOut / (#TxIn + #GenGAL)');
  Ti{i}=select(Ti{i},{'TSDF_EPA_ID','FAC_NAME','Year','WC','Facil','GenGAL','Import', ...
                      'DispGAL','TxIn','TxOut','TxLosses','TxMeas','DK','Ev','RFO_CA', ...
                      'ExportMix','Wastewater','HazWaste','Incin','Rejuv'});

  
  
                      
                      
end

%T=[Ti{1};Ti{2};Ti{3}];
%Ta=[Tia{1};Tia{2};Tia{3}];



function S=adjust(S,Disp,F,field)
%fprintf(1,'%s %f\n',field,Disp*F.(field))
S.(field)=S.(field)+floor(Disp*F.(field));


%T_list=accum(select(T,{'TSDF_EPA_ID','WASTE_STATE_CODE','Class'}),'mcc', ...
%             {'','','|'});
%E={T_list.TSDF_EPA_ID};


% % this file

% C=[0,0,0]; % generation corrections

% Fates={'Wast

% for i=1:3
%   wc=['22' num2str(i)];
%   Ti=select(filter(T,'WASTE_STATE_CODE',{@strcmp},wc),...
%             {'TSDF_EPA_ID','GenGAL','Import','DispGAL','TxOut','TxLosses','Class',...
%              'H040','H050','H061','H129','H132','H135'});
%   Tia=accum(Ti,'daaaaadaaaaaa','');
%   [Ti_CA,M_CA]=filter(Ti,'Class',{@regexp},'.*-CA');
%   Ti_US=Ti(~M_CA);
%   Ti_CAa=accum(select(Ti_CA,{'DispGal','H040','H050','H061','H129','H132','H135'}),'aaaaaaa','');
%   D(i).WC=wc;
%   D(i).Gen=Tia.DispGAL + Tia.TxLosses - Tia.Import;
%   D(i).Import=Tia.Import;
%   D(i).Tx=Tia.TxOut;
%   D(i).TxLosses=Tia.TxLosses;
%   D(i).Wastewater=Tia.H135;
%   D(i).HazWaste=Tia.H132;
%   D(i).Incin=Tia.H040;
%   D(i).RFO_CA=0;
%   D(i).ExportMix=0;
%   D(i).DK=0;
%   D(i).Ev=0;
%   for j=1:length(Ti)
%     F=filter(PI,{'EPAID','WC'},{@strcmp},{Ti(j).TSDF_EPA_ID,wc});
%     if isempty(F)
%       F=filter(PI,{'EPAID','WC'},{@strcmp},{'Default',wc});
%     end
%     my_rfo=Ti(j).H050+Ti(j).H061;
    
%   end
  
% end
