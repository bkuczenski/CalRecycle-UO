function [Rnode,MAN,Rin]=cr_node(CRData,year,varargin)
% function [Rnode,MAN,Rin]=cr_node(CRData,year)
% old:function [Rin,MAN,Rnode]=cr_node(H,P,T,year)
%
% Generates input output data for nodes on a directed graph implied by the
% CalRecycle data.  Collects inputs on one side, outputs on the other, and
% a string list of destination EPAIDs if known.
%
% Ultimately, the core of this should be abstracted into a formal mechanism.
% 
% Constructs a stock data table, R, with inputs on the left, UID (EPAID) down the
% middle, and outputs on the right.  This is Rin, and it is built by looking up on
% EPAIDs into the argument data tables.  Then, moves flows from outputs to inputs,
% generating a manifest record of flow transfers.  At the end, all inflow stocks and
% all internal outflow stocks should be emptied.  The remainder shows addition to
% non-internal outflow stocks resulting from the input data (Rout).  This is saved
% but not returned bc not presently useful.
%
% Rnode shows mass balances for nodes which receive shipments, to match Tn from
% md_node. 
%
% Tr is a mass balance on terminal nodes, just like in md_node.m
%
% Inputs should use CRData_Hauler, CRData_Proc, CRData_Txfr_DC.  These should be
% properly appended with data corrections as appropriate.
%
%%%% ==================================================
%% nomenclature
%% H, P, T are data records CRData.Hauler, CRData.Proc, and CRData.Txfr_DC
%%
%% documented in 
%%
%% E = reference list of EPAIDs generated from H, P, T
%%
%% Ha, Pa, Ta = accum on EPAIDs by year and by query
%% to build 
%%
%% TO this I want to add manual transfers before doing the computation.
%%
%% lookup: R is a constructed query using elookup, against Ha, Pa, Ta
%%
%%%% ==================================================

do_sanity_check=true;
printcsv=false;

while ~isempty(varargin)
  if ischar(varargin{1})
    switch varargin{1}(1:3)
      case 'pri'
        printcsv=true;
      otherwise
        disp(['ignoring arg ''' varargin{1} ''''])
    end
  else
    disp('Don''t understand argument:')
    disp(varargin{1})
    keyboard
  end
  varargin(1)=[];
end

% argument handling

H=CRData.Hauler; P=CRData.Proc; T=CRData.Txfr_DC;
    


% these are globals
yy=num2str(year);
EPAID_DEST_UNKNOWN='CA9999999999';
EPAID_SRC_UNKNOWN='CA0000000000';

%% ----------------------------------------
% Unit Conversion

% ss=savefile
ss.Year=year;
ss.OrigUnits='Gallons';

% ss.Conv='0.003313 t/Gal (875 g/cm3)';
ss.Conv='';
ss.ConvFactor=1;
ss.ConvUnits='not converted'

disp('not converting')

TitleBlock={  ['Terminal Nodes in CalRecycle Data, Year ' yy ],
              ['Orig Units: ' ss.OrigUnits ],
              ['Conversion Factor: ' ss.Conv ],
              ['Display Units: ' ss.ConvUnits],
              datestr(now)};

disp(char(TitleBlock{:}))

%% ----------------------------------------
% OK GO



%% Begin the CalRecycle query
% ----------------------------------------
% step 1: list of EPAIDs
%
% generate list of facilities
E=accum(cell2struct({H.EPAIDNumber P.EPAIDNumber T.SrcEPAID T.DestEPAID},'EPAID'),'m');
% E is geolookup because geo context is Facilities

%% SELECT
Ha=accum(filter(H,'Year',{@eq},year),'dmdmddddddadddddddadadda','');
Pa=accum(filter(P,'Year',{@eq},year),'dmdmddddddddaddaaaaaaaaaddda','');
Ta=accum(filter(T,'Year',{@eq},year),'mmdmaaadd','');

% add together 'other haulers'
Ha=fieldop(Ha,'LubOtherHaulersGallons',...
          '#LubOtherHaulersGallons + #IndOtherHaulersGallons');

% detect self-transfers
% S is like a complement to R
x=cellfun(@strcmp,{Ta.DestEPAID},{Ta.SrcEPAID});
S=Ta(x);   % store them
Ta=Ta(~x); % then remove them from the data set

Ts=accum(Ta,'mcmaaaa',{'C','C',','}); % accumulate non-self-transfers by EPAID
Td=accum(Ta,'cmmaaaa',{'C','C',','}); % accumulate non-self-transfers by EPAID

%keyboard

%% select data columns

%% R is mass balance table, showing flows into and out of a set of stocks
%% as expressed in literal CR data? no accumulated CR data
%% M is a logical list of matches

R=rmfield(E,'Count');
M=logical(zeros(size(R)));

[R,M]=elookup(R,M,Ha,'EPAIDNumber','GrandTotalGallons','H_Total');

[R,M]=elookup(R,M,Ha,'EPAIDNumber','LubOtherHaulersGallons','H_Consol');
% based on the comparison to other fields, it looks like H_TxIn is not redundant to
% CR transfers- rather, it looks like it describes consolidation.  In most cases
% where H_Consol is nonzero, H_Total = TxOut (or at least the H_Consol amount is far
% greater than the discrepancy).  The only two cases [2010] where this does not hold
% are already managed correctly by current code: Asbury (presumptive txfr to DK) and
% Thermofluids (report as self-transfer).  
%
% So: interpret H_Consol as informational, not as a double-counting adjustment.

[R,M]=elookup(R,M,Td,'DestEPAID','CTotal','Tx_In');

[R,M]=elookup(R,M,Pa,'EPAIDNumber','GrandTotalOilReceivedGallons','P_Total');

R=orderfields(R,[2 3 4 5 1]);

[R,M]=elookup(R,M,Pa,'EPAIDNumber','RecycledOilTotalGallons','P_RFO');
[R,M]=elookup(R,M,Pa,'EPAIDNumber','ResidualMaterialTotalGallons','P_Waste');
[R,M]=elookup(R,M,Pa,'EPAIDNumber','TotalTransferedGallons','P_TxOut');
[R,M]=elookup(R,M,Ha,'EPAIDNumber','TotalTransferedGallons','H_TxOut');

[R,M]=elookup(R,M,Ts,'SrcEPAID','CTotal','Tx_Out');
%[R,M]=elookup(R,M,Ts,'SrcEPAID','CDestEPAID','T_Destinations');

% and drop EPAIDs that didn't match any
R=R(M);

R=sort(sort(sort(R,'H_Total','descend'),'Tx_In','descend'),'P_Total','descend');
R=vlookup(R,'EPAID',S,'SrcEPAID','Total','zero');
R=mvfield(R,'Total','SelfTxfr');

if do_sanity_check
  show(R)
  disp('Sanity Check for H_Consol')
  keyboard
end
%%%%% now: break this into Processors, Haulers, and Intermediates.

Rin=R; % archive version

[PP,MP]=filter(R,{'P_Total'},{@eq},0,1);
[HH,MH]=filter(R,{'P_Total','Tx_In','SelfTxfr'},{@eq},{0,0,0});
MH=MH(:,end);

%% TT is transfer recipients who are not processors
TT=R(~MP & ~MH);


% construct a manifest record from transfer record, subtracting out generation and
% terminal processing

% Clean Up: 
R=rmfield(R,'H_TxOut');  % this was observed to be inconsistent- see h_t compare
                         % or whatnot



%%%% ==================================================
%% Now I want to lookup into DTSC's more carefully constructed, shallower 
%  dataset, which is in manfiles, to cross-list entries.  
% use year

% DTSCman=load([ '../HWTS/Tanner' num2str(year) '/



%% ----------------------------------------
%% now- perform flows.  move stuff from in stocks to out stocks in symmetric
%% transfers , which are stored as Manifests

MAN=struct('GEN_EPA_ID',{},'TSDF_EPA_ID',{},...
           'METH_CODE',{},'GALLONS',[]);

%% now accumulate 
%
% perform queries on Ta and other data structs and build up manifest list and
% group classification.
%
% group_a = G->T direct;
% group_b = G->Tx, H141
% group_c = Tx->T
%
% The base data here is very simple: there are no transfer stations.  Every
% transfer is terminal.  In the Rin table, flows come in H_Total, go out SelfTxfr
% or Tx_Out, come in elsewhere Tx_In and end.  The only exceptions are in PP.
%
% that means the CR data will never be comparable to the DTSC data unless I make
% it so, manually.  that is counter to the spirit of this exercise.  So, I assume
% there are no transfer stations and no groups b or c.  Everything is in group a.
% I don't even want to give back groups.  all I want to do is provide a mass
% balance matrix. 

%keyboard

L=0;

%% first, handle self-transfers.  These are easy because they are all group a in
%CR data.
for i=1:length(S) % self-txfrs
  L=L+1;
  MAN(L).GEN_EPA_ID=S(i).SrcEPAID;
  MAN(L).TSDF_EPA_ID=S(i).DestEPAID;
  MAN(L).GALLONS=S(i).Total;
  src=find(strcmp({R(:).EPAID},S(i).SrcEPAID));
  
  R(src).SelfTxfr = R(src).SelfTxfr - S(i).Total;
  R(src).H_Total = R(src).H_Total - S(i).Total;
  MAN(L).METH_CODE='C142'; % self-transfer
end

Ta=sort(Ta,'Total','ascend');

for i=1:length(Ta) % self-txfrs already removed
  L=L+1;
  MAN(L).GEN_EPA_ID=Ta(i).SrcEPAID;
  MAN(L).TSDF_EPA_ID=Ta(i).DestEPAID;
  MAN(L).GALLONS=Ta(i).Total;
  
  src=find(strcmp({R(:).EPAID},Ta(i).SrcEPAID));
  dest=find(strcmp({R(:).EPAID},Ta(i).DestEPAID));
  
  % if src==dest
  %   disp('Found a mysterious self-transfer')
  %   keyboard
  % end
  R(src).Tx_Out=R(src).Tx_Out - Ta(i).Total;
  if MP(src) % it's a processor -- take it "off the top".  ignore P_TxOut
    R(src).P_Total=R(src).P_Total - Ta(i).Total;
    %R(src).P_TxOut=R(src).P_TxOut - Ta(i).Total;
  else % it's a hauler or intermediate. Either way, it had to come from somewhere 
    R(src).H_Total=R(src).H_Total - Ta(i).Total;
  end
  
  R(dest).Tx_In=R(dest).Tx_In - Ta(i).Total;
  if MP(dest) % it's a processor
    R(dest).P_Total=R(dest).P_Total - Ta(i).Total;
    MAN(L).METH_CODE='C039';
  else
    MAN(L).METH_CODE='C141';
  end
end

% Add in correctional transfers
if isfield(CRData,'Do_Txfr_Corr') & CRData.Do_Txfr_Corr==true
  Tc=CRData.Txfr_Corr;
  ss.Txfr_Corr=true;
  for i=1:length(Tc)
    my_in=accum(filter(MAN,'TSDF_EPA_ID',{@strcmp},Tc(i).SrcEPAID),'ddda','');
    my_out=accum(filter(MAN,{'GEN_EPA_ID','METH_CODE'},{@strcmp}, ...
                        {Tc(i).SrcEPAID,'C142'},{0,1}), 'ddda','');
    if isempty(my_in) my_in_gal=0;
    else my_in_gal=my_in.GALLONS;
    end
    if isempty(my_out) my_out_gal=0;
    else my_out_gal=my_out.GALLONS;
    end
    corr_gal=my_in_gal-my_out_gal;
    if corr_gal>0
      disp(['Adding corrective transfer for ' Tc(i).SrcEPAID ' to ' Tc(i).DestEPAID ...
           ': ' num2str(corr_gal) ' gal'])
      L=L+1;
      MAN(L).GEN_EPA_ID=Tc(i).SrcEPAID;
      MAN(L).TSDF_EPA_ID=Tc(i).DestEPAID;
      MAN(L).GALLONS=corr_gal;
      MAN(L).METH_CODE='Y039';
      % need to correct Rin
      src=find(strcmp({R(:).EPAID},Tc(i).SrcEPAID));
      dest=find(strcmp({R(:).EPAID},Tc(i).DestEPAID));
      Rin(src).Tx_Out=Rin(src).Tx_Out+corr_gal;
      Rin(dest).Tx_In=Rin(dest).Tx_In+corr_gal;
      
    else
      disp(['No corrective transfer to add for ' Tc(i).SrcEPAID ]);
    end
  end
else
  ss.Txfr_Corr=false;
  Tc=struct('SrcEPAID',[]);
end

% now clean up residuals (stored in H_Total)
for i=1:length(R)
  if R(i).H_Total
    L=L+1;
    if MP(i) % processor
      MAN(L).GEN_EPA_ID=R(i).EPAID;
      MAN(L).TSDF_EPA_ID=R(i).EPAID;
      MAN(L).GALLONS=R(i).H_Total;
      MAN(L).METH_CODE='C039';
      R(i).P_Total = R(i).P_Total - R(i).H_Total;
    else % hauler or intermediate
      if R(i).H_Total > 0 % hauler reports more incoming than outgoing
        if strcmp(R(i).EPAID(1:2),'CA') % in-state: destination unknown
          MAN(L).GEN_EPA_ID=R(i).EPAID;
          MAN(L).GALLONS=R(i).H_Total;
          if any(strcmp({Tc.SrcEPAID},R(i).EPAID)) % - in correction list
            k=find(strcmp({Tc.SrcEPAID},R(i).EPAID));
            MAN(L).TSDF_EPA_ID=Tc(k).DestEPAID;
            MAN(L).METH_CODE='Y039';
            % don't add in dest for dest_unknown
            dest=find(strcmp({R(:).EPAID},MAN(L).TSDF_EPA_ID));
            Rin(dest).Tx_In=Rin(dest).Tx_In+R(i).H_Total;
          else
            MAN(L).TSDF_EPA_ID=EPAID_DEST_UNKNOWN;
            MAN(L).METH_CODE='C143';
            % don't add in dest for dest_unknown
          end
          % need to correct Rin
          disp(['Adding hauler outbound correction for ' R(i).EPAID ' to ' ...
                MAN(L).TSDF_EPA_ID ': ' num2str(R(i).H_Total) ' gal'])
          src=i;
          Rin(src).Tx_Out=Rin(src).Tx_Out+R(i).H_Total;
        else % out-of-state: treat as self-transfer
          MAN(L).GEN_EPA_ID=R(i).EPAID;
          MAN(L).TSDF_EPA_ID=R(i).EPAID;
          MAN(L).GALLONS=R(i).H_Total;
          MAN(L).METH_CODE='C142';
        end
      else % more outgoing than incoming: source unknown
        MAN(L).GEN_EPA_ID=EPAID_SRC_UNKNOWN;
        MAN(L).TSDF_EPA_ID=R(i).EPAID;
        MAN(L).GALLONS= -R(i).H_Total;
        MAN(L).METH_CODE='C144';
      end
    end
    
    R(i).H_Total = 0;
  end
end

% Processor inbound that is not manifested
FMP=find(MP);

for i=1:length(FMP)
  if R(i).P_Total
    L=L+1;
    MAN(L).GEN_EPA_ID=EPAID_SRC_UNKNOWN;
    MAN(L).TSDF_EPA_ID=R(i).EPAID;
    MAN(L).GALLONS=R(i).P_Total;
    MAN(L).METH_CODE='C139';
    R(i).P_Total=0;
  end
end




% at this point, it's all done-- just do county lookup
[MAN(:).WASTE_STATE_CODE]=deal('221');
MAN=flookup(MAN,'GEN_EPA_ID','FAC_CNTY');
MAN=mvfield(MAN,'FAC_CNTY','GEN_CNTY');
MAN=flookup(MAN,'TSDF_EPA_ID','FAC_CNTY');
MAN=mvfield(MAN,'FAC_CNTY','TSDF_CNTY');
MAN=orderfields(MAN,[1 6 2 7 5 3 4 ]);

% Now build mass balance matrix.

TSDs = accum(MAN,'ddmddma','');

% leave out processor-reported balancing quantity
Rn = accum(filter(MAN,'METH_CODE',{@strcmp},'C139',1),'ddmdmda','Dest');
Rn = rmfield(Rn,'Count');
Rn = orderfields(Rn, [2 1 3]);

% inputs: hauling, Tx_In, Src unknown

Rn = vlookup(Rn,'TSDF_EPA_ID',Rin,'EPAID','H_Total','zer');
Rn = vlookup(Rn,'TSDF_EPA_ID',Rin,'EPAID','Tx_In','zer');

Rn = vlookup(Rn,'TSDF_EPA_ID',filter(TSDs,'METH_CODE',{@strcmp},'C144'),'TSDF_EPA_ID',...
             'GALLONS','zer');
Rn = mvfield(Rn,'GALLONS','C144');

% outputs: Tx_Out, self-transfers, products, balance
  
Rn = vlookup(Rn,'TSDF_EPA_ID',Rin,'EPAID','Tx_Out','zer');

Rn = vlookup(Rn,'TSDF_EPA_ID',filter(TSDs,'METH_CODE',{@strcmp},'C142'),'TSDF_EPA_ID',...
             'GALLONS','zer');
Rn = mvfield(Rn,'GALLONS','C142');

Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','GrandTotalOilReceivedGallons','zer');
Rn = mvfield(Rn,'GrandTotalOilReceivedGallons','ReportedRcvd');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','RecycledOilNeutralBaseStockGallons','zer');
Rn = mvfield(Rn,'RecycledOilNeutralBaseStockGallons','BaseOil');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','RecycledOilIndustrialOilGallons','zer');
Rn = mvfield(Rn,'RecycledOilIndustrialOilGallons','IndOil');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','RecycledOilFuelOilGallons','zer');
Rn = mvfield(Rn,'RecycledOilFuelOilGallons','Fuels');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','RecycledOilAsphaltGallons','zer');
Rn = mvfield(Rn,'RecycledOilAsphaltGallons','Asphalt');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','RecycledOilConsumedGallons','zer');
Rn = mvfield(Rn,'RecycledOilConsumedGallons','consumed');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','ResidualMaterialNonhazardousGallons','zer');
Rn = mvfield(Rn,'ResidualMaterialNonhazardousGallons','NonHaz');
Rn = vlookup(Rn,'TSDF_EPA_ID',Pa,'EPAIDNumber','ResidualMaterialHazardousGallons','zer');
Rn = mvfield(Rn,'ResidualMaterialHazardousGallons','Haz');

% gen + inbound - outbound: DestGALLONS is C039 + C139 + C141 + C142 + C144
% "reported-recycled" + Tx_In + Self Transfer + Source-unknown
% Self Transfer is already counted in H_Total so subtract it back out.
Rn = fieldop(Rn,'balance','#H_Total + #DestGALLONS - #C142 - #Tx_Out');%...
%                    ' - ( #BaseOil + #IndOil + #Fuels + #Asphalt + #consumed + ' ...
%                    ' #NonHaz + #Haz )']);

nf=length(fieldnames(Rn));
Rn = orderfields(Rn,[ 1 3 4 5 6 7 8 nf 2 9:(nf-1)]);


Rout=R;  
Rnode=sort(Rn,'DestGALLONS','descend');

ss.(['Q_' num2str(year)])=MAN;
ss.Rin=Rin;
ss.Rout=Rout;
ss.Rnode=Rnode;

varname=['CR_' yy];

eval([varname '=ss;']);
%CR.R
save([varname '.mat'],varname)
% and this is done.    

disp('pulling meth_code totals')

ByMeth=sort(accum(MAN,'dddddma',''),2,'descend');
ByMeth=filter(ByMeth,'METH_CODE',{@regexp},'[A-Z]');
ByMeth=meth_lookup(ByMeth);
show(ByMeth)
  
if printcsv
  csvfile=['CR-nodes-' yy '.csv'];
  if exist(csvfile)
    disp(['Deleting csvfile ' csvfile])
    delete(csvfile);
  end
  show(sort(flookup(Rn,'TSDF_EPA_ID','FAC_NAME','inplace'),'balance','ascend'),'',...
       csvfile,',*',TitleBlock)
  show(ByMeth,'',csvfile,',*')
  show(sort(flookup(Rn,'TSDF_EPA_ID','FAC_NAME','inplace'),'balance','ascend'))
end

  
%  if any(strcmp({TT(:).EPAID},Ta(i).SrcEPAID))
%    % originates in intermediate






%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% elookup
%%
%% [ query, match ] = elookup( q+m , target table, keyname, refname, rename_to

function [R,M]=elookup(R,M,D,K,F,NF)
[R,m]=vlookup(R,'EPAID',D,K,F,'zer');
R=mvfield(R,F,NF);
M=M|m;


