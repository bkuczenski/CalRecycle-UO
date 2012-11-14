function [D,chk]=mfa_extract(varargin)
% function D=mfa_extract(year)
% function D=mfa_extract(CRData,year)
% function D=mfa_extract(CRData,year,opts)
% 
% Extracts MFA data from collected 
% I should have started with this on Thursday.  Except I had no idea what CR and
% MD would look like.
%
% D . <source> . <meas> . <component> = amount
%                       . Units
%                       . MassFrac . <component> = scalar
%
% Eventually, MassFrac will be a vector index into a table of substances.  But for
% now it is just the fraction of the flow that is of interest to us.
%
% Source: CRSales
%          Flow: Sales [Mgal] <Lub, Ind>
%          Flow: SalesComp [Mgal] <LubMC, LubGov, LubComm, LubOther, Ind>
%
% Source: CRHauler
%          Flow: Hauling [Mgal] <Lub <CC, Ind, Mar, Agr, Gov, Imp, Consol>, 
%                                Ind <CC, Ind, Mar, Agr, Gov, Imp, Consol>>
%
% Source: MD.Tn
%          Flow: UOGen [Mgal] <WC_221, WC_222, WC_223>
%          Flow: Geo [Mgal] <Imp, Instate, Exp>
%          Flow: Hauling [Mgal] <Direct, TxStn, TxLost>
%          Flow: UODisp [Mgal] <H039, H040, H050, H061, H132, H135, Other>
%          Flow: MDProducts <BaseOil, LightFuels, RFO, Asphalt>
%
% Source: CR.Rnode
%          Flow: Geo [Mgal] <Instate, Exp>
%          Flow: CRProducts <BaseOil, LightFuels, RFO, Asphalt>
%
%
%
% Uses the table FacilityOut.csv, which is a manually-curated mapping from data
% types to flow components.  Each column in FacilityOut is used to confer a
% different type of information about the facility.
%
% Each parameter can be real, in which case the incoming flow is split between the
% outputs using interpolation.
%
% FUEL_CHAR -> for fuel production, are we talking about RFO or high-grade fuels?
%
%      0  ----|----  1
%     RFO        LightFuels
%
% Default is 0.
% 
% K221, K222, K223 -> describes the fraction of the input that winds up as product,
% and the fraction that is residual (either separated water, asphalt fluxes, or other
% contaminants),by waste code.  For facilities that report as processors to
% CalRecycle, the actual ratio from their reported value is used.
%
%      0  ----|----  1
% All Residue     All Fuel
%
% Default is 0.9 for 221, 0.8 for 222, 0.15 for 223 - defined in FacilityOut.csv
%
%  OK, maybe with this I can wrap this up.


% crufty:
%  PROD_CHAR -> describes the "default" product from the facility.  This is very
%  ad hoc, but necessary because:
% 
% (1) in MD context, H039 / unknown make up the vast majority of disposal and 
% (2) in CR context, many facilities which do not report themselves as processors
% nonetheless have a net receipt of material.  Assuming the vast majority of these
% are transfer stations, it is incumbent on us to estimate where they transfer it
% to (e.g. to RFO, ReRe, or some kind of sequestration.
%
% So in the MD context, this describes the ultimate fate of the incoming material,
% according to the following highly idiomatic scheme:
%
%      0  ----|----  1  ----|----  2
%  Dest/Disp       Fuel         Re-refining
% 
% Default is 1.  If the products of a given facility are thought to be bound to a
% specific other facility, use the TxfrCorr mechanism instead.
%
use_md2=false;

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

D.Year=num2str(year);
D.CR.Units='Mgal';


% Source: CRSales
%          Flow: Sales [Mgal] <Lub, Ind>
%          Flow: SalesComp [Mgal] <LubMC, LubGov, LubComm, LubOther, Ind>
%
% need to get quarterly and subcategory data into matlab.. but not today
CS=accum(filter(CRData.Sales,'Year',{@eq},year),'maaaa','');
D.CR.Sales.Lub = CS.LubCons;
D.CR.Sales.Ind = CS.IndCons;
D.CR.Sales.Total = CS.LubCons+CS.IndCons;

% =========================================================================
% Hauling

% Source: CRHauler
%          Flow: Hauling [Mgal] <Lub <CC, Ind, Mar, Agr, Gov, Imp, Consol>, 
%                                Ind <CC, Ind, Mar, Agr, Gov, Imp, Consol>>
%

HD=accum(filter(CRData.Hauler,'Year',{@eq},year),'dmddaaaaaaad','');
HD=mvfield(HD,'LubCollectionStationsGallons','CC');
HD=mvfield(HD,'LubIndustrialGallons','Inds');
HD=mvfield(HD,'LubMarineGallons','Mar');
HD=mvfield(HD,'LubAgriculturalGallons','Agr');
HD=mvfield(HD,'LubGovernmentGallons','Gov');
HD=mvfield(HD,'LubOutOfStateGallons','Import');
HD=mvfield(HD,'LubOtherHaulersGallons','Consol');
HD=rmfield(HD,{'Year','Count'});
HD.Total=sum(struct2array(HD));
HD.TotalInState=HD.Total-HD.Import;

%HD=scalestruct(HD,1e-6);

HI=accum(filter(CRData.Hauler,'Year',{@eq},year),'dmddddddddddaaaaaaad','');
HI=mvfield(HI,'IndCollectionStationsGallons','CC');
HI=mvfield(HI,'IndIndustrialGallons','Inds');
HI=mvfield(HI,'IndMarineGallons','Mar');
HI=mvfield(HI,'IndAgriculturalGallons','Agr');
HI=mvfield(HI,'IndGovernmentGallons','Gov');
HI=mvfield(HI,'IndOutOfStateGallons','Import');
HI=mvfield(HI,'IndOtherHaulersGallons','Consol');
HI=rmfield(HI,{'Year','Count'});
HI.Total=sum(struct2array(HI));
HI.TotalInState=HI.Total-HI.Import;

%HI=scalestruct(HI,1e-6);

Hauling = HD+HI;

Hauling.Lub=HD;

Hauling.Ind=HI;

D.CR.Hauling=Hauling;

% surely, eventually, there is an elegant way to automate this sort of thing.
% sure there is: calculation on demand.

% =========================================================================
% DTSC Manifests

% Source: MD.Tn
%          Flow: UOGen [Mgal] <WC_221, WC_222, WC_223>
%          Flow: Geog [Mgal] <Imp, Instate, Exp> -- forget imports
%          Flow: Hauling [Mgal] <Direct, TxStn, TxLost>
%          Flow: UODisp [Mgal] <H039, H040, H050, H061, H132, H135, Other>
%          Flow: MDProducts <BaseOil, LightFuels, RFO, Asphalt>
%

if ~exist([md_prefix num2str(year) '_221.mat'])
  md_node(year,221);
end
MD=load([md_prefix num2str(year) '_221.mat']);
Tn221=MD.(['Tn_' num2str(year) '_221']);
TSDF221=MD.(['TSDF_' num2str(year) '_221']);
Tn221a=accum( Tn221, 'dadaaa','');

if ~exist([md_prefix num2str(year) '_222.mat'])
  md_node(year,222);
end
MD=load([md_prefix num2str(year) '_222.mat']);
Tn222=MD.(['Tn_' num2str(year) '_222']);
TSDF222=MD.(['TSDF_' num2str(year) '_222']);
Tn222a=accum( Tn222,'dadaaa','');

if ~exist([md_prefix num2str(year) '_223.mat'])
  md_node(year,223);
end
MD=load([md_prefix num2str(year) '_223.mat']);
Tn223=MD.(['Tn_' num2str(year) '_223']);
TSDF223=MD.(['TSDF_' num2str(year) '_223']);
Tn223a=accum(Tn223,'dadaaa','');

D.MD.Units='Mgal';


%% ----------------------------------------
%% UOGen, by wastecode (here we could use massfrac, eventually, if we wanted..

%keyboard

D.MD.UOGen.WC_221=Tn221a.DispGAL + Tn221a.TxLosses;
D.MD.UOGen.WC_222=Tn222a.DispGAL + Tn222a.TxLosses;
D.MD.UOGen.WC_223=Tn223a.DispGAL + Tn223a.TxLosses;

D.MD.UOGen.Total=sum(struct2array(D.MD.UOGen));

%% ----------------------------------------
%% exports by wastecode

D.MD.Geog.Total = D.MD.UOGen.Total;
D.MD.Geog.WC_221_ex = getfield( accum( ...
    filter(Tn221,'TSDF_EPA_ID',{@regexp},'^CA',1), 'da',''), 'DispGAL');
D.MD.Geog.WC_222_ex = getfield( accum( ...
    filter(Tn222,'TSDF_EPA_ID',{@regexp},'^CA',1), 'da',''), 'DispGAL');
D.MD.Geog.WC_223_ex = getfield( accum( ...
    filter(Tn223,'TSDF_EPA_ID',{@regexp},'^CA',1), 'da',''), 'DispGAL');

D.MD.Geog.Exports = D.MD.Geog.WC_221_ex ...
    + D.MD.Geog.WC_222_ex ...
    + D.MD.Geog.WC_223_ex;
    

%% ----------------------------------------
%% hauling by topology

H.Total = D.MD.UOGen.Total;
if use_md2
  H=mdhaul2(H,Tn221a,221);
  H=mdhaul2(H,Tn222a,222);
  H=mdhaul2(H,Tn223a,223);
else
  H=mdhaul(H,Tn221a,221);
  H=mdhaul(H,Tn222a,222);
  H=mdhaul(H,Tn223a,223);
end
% H.WC_221.TxStation = Tn221a.TxIn;
% H.WC_221.TxLosses = Tn221a.TxLosses;
% H.WC_221.Direct = Tn221a.DispGAL - Tn221a.TxIn;

% H.WC_222.TxStation = Tn222a.TxIn;
% H.WC_222.TxLosses = Tn222a.TxLosses;
% H.WC_222.Direct = Tn222a.DispGAL - Tn222a.TxIn;

% H.WC_223.TxStation = Tn223a.TxIn;
% H.WC_223.TxLosses = Tn223a.TxLosses;
% H.WC_223.Direct = Tn223a.DispGAL - Tn223a.TxIn;

% H.Direct = H.WC_221.Direct + H.WC_222.Direct + H.WC_223.Direct;
% H.TxStation = H.WC_221.TxStation + H.WC_222.TxStation + H.WC_223.TxStation;
% H.TxLosses = H.WC_221.TxLosses + H.WC_222.TxLosses + H.WC_223.TxLosses;

D.MD.Hauling = H;

%% ----------------------------------------
%% Disposition by Method code

MC=struct;
MC=mddisp(MC,Tn221,221);
MC=mddisp(MC,Tn222,222);
MC=mddisp(MC,Tn223,223);

D.MD.Disposition=MC;

%% ----------------------------------------
%          Flow: MDProducts <BaseOil, LightFuels, RFO, Asphalt>
% For this, we need to draw on the data in the CR reports to craft unit outputs.
% This is the first time I actually use a technique from the material flow defn-
% basically a sum over all activity in the domain.
%
% Approach: given a total input (221+222+223 or CR balance), figure out a mass
% fraction of oil using FacilityOut K-values.  Then 
%
% for each facility in Tn, first check to see whether it reports as a processor in
% cal recycle.  If it does, use its base oil | asphalt | fuels to figure out
% a unit output per valuable input.  
%
% Look up FUEL_CHAR in FacilityOut or use default. (no way to infer this)
%

myCR=load(['CR_' num2str(year)]);
CR=myCR.(['CR_' num2str(year)]);

CRa=accum(CR.Rnode,'daaaaaaada','');

D.CR.Processed.Total = CRa.balance;
D.CR.Processed.Exports = getfield(accum(...
    filter(CR.Rnode,'TSDF_EPA_ID',{@regexp},'^CA',1),'daaaaaaa',''),'balance');
D.CR.Processed.ReportedRcvd=CRa.ReportedRcvd;

% Here we just want a long list of EPAIDs, the union of those listed in 221, 222,
% 223, and Rnode.  Then we go through and accumulate the results over all EPAIDs.
EID=unique({Tn221.TSDF_EPA_ID Tn222.TSDF_EPA_ID Tn223.TSDF_EPA_ID CR.Rnode.TSDF_EPA_ID});

MDP.BaseOil=0;
MDP.LightFuels=0;
MDP.RFO=0;
MDP.Asphalt=0;

CRP=MDP;

fprintf('%s','Reading FacilityOut parameters: ')
F_Params=read_dat('FacilityOut.csv',',',{'s','d','d','d','d'});

CRmatch=0;

TN{1}=Tn221;
TN{2}=Tn222;
TN{3}=Tn223;

for i=1:length(EID)
  [Prod_MD,Prod_CR]=fac_xform(EID{i},CR.Rnode,TN,F_Params);
  MDP.BaseOil = MDP.BaseOil + Prod_MD(1);
  MDP.LightFuels = MDP.LightFuels + Prod_MD(2);
  MDP.RFO = MDP.RFO + Prod_MD(3);
  MDP.Asphalt = MDP.Asphalt + Prod_MD(4);
  
  CRP.BaseOil = CRP.BaseOil + Prod_CR(1);
  CRP.LightFuels = CRP.LightFuels + Prod_CR(2);
  CRP.RFO = CRP.RFO + Prod_CR(3);
  CRP.Asphalt = CRP.Asphalt + Prod_CR(4);

  if sum(Prod_CR)>0
    CRmatch=CRmatch+1;
    chk(CRmatch).EPAID=EID{i};
    chk(CRmatch).BaseOil=Prod_CR(1);
    chk(CRmatch).LightFuels=Prod_CR(2);
    chk(CRmatch).RFO=Prod_CR(3);
    chk(CRmatch).Asphalt=Prod_CR(4);
  end
end

D.MD.Products=MDP;
D.MD.Products.Total=sum(struct2array(MDP));

D.CR.Products=CRP;
D.CR.Products.Total=sum(struct2array(CRP));

D=scalestruct(D,1e-6,{'Year','Sales','Units'}); % exclude sales
D.YearNum=year;


% =========================================================================
% Hauling

% Source: CR.Rnode
%          Flow: Geo [Mgal] <Instate, Exp>
%          Flow: CRProducts <BaseOil, LightFuels, RFO, Asphalt>
%


function [Prod_MD,Prod_CR]=fac_xform(ID,Rnode,TN,F_Params)
RR=find(strcmp({Rnode.TSDF_EPA_ID},ID));

for i=1:3
  T=find(strcmp({TN{i}.TSDF_EPA_ID},ID));

  if ~isempty(T)
    Disp(i)=TN{i}(T).H039;
    if isfield(TN{i}(T),'H050')
      Onsite(i)=TN{i}(T).H050;
    else
      Onsite(i)=0;
    end
    if isfield(TN{i}(T),'H061')
      Offsite(i)=TN{i}(T).H061;
    else
      Offsite(i)=0;
    end
  else
    Disp(i)=0;
    Onsite(i)=0;
    Offsite(i)=0;
  end
end

H039_vec=Disp(:);
RFO_vec=Onsite(:)+Offsite(:);

ind=find(strcmp({F_Params.TSDF_EPA_ID},ID));
if isempty(ind)
  ind=1;
end

FUEL_CHAR=F_Params(ind).FUEL_CHAR;
K=[ F_Params(ind).K221 F_Params(ind).K222 F_Params(ind).K223];

if ~isempty(RR)
  % there is a CR entry
  balance=Rnode(RR).balance;
  if Rnode(RR).ReportedRcvd ~=0
    % it reports as a processor
    BO=Rnode(RR).BaseOil;
    As=Rnode(RR).Asphalt;
    Fu=Rnode(RR).Fuels;
    Wa=Rnode(RR).NonHaz + Rnode(RR).Haz;
    
    util=(BO+As+Fu)/(BO+As+Fu+Wa);
    
    valuable_in = util * sum(H039_vec);
    
    out_vec=[BO Fu*FUEL_CHAR Fu*(1-FUEL_CHAR) As]/Rnode(RR).ReportedRcvd;
  else
    % no processor- rely on FUEL_CHAR (or other lookups) to describe flow
    valuable_in = K*H039_vec;
    out_vec=[0 FUEL_CHAR 1-FUEL_CHAR 0];
  end
else
  valuable_in = K*H039_vec;
  out_vec=[0 FUEL_CHAR 1-FUEL_CHAR 0];
  balance=0;
end
RFO_in = K*RFO_vec;

try
  Prod_MD=floor(out_vec*valuable_in + [0 0 1 0]*RFO_in);
catch
  keyboard
end

%MD also contains info about other fates: H050, H061 both count as RFO

Prod_CR=floor(out_vec*balance);

  

function MC=mddisp(MC,Tn,wc)
if ~isfield(MC,'Total')
  MC.Total=0;
end
foo.Total=sum([Tn.DispGAL]);
% pull H names
FN=fieldnames(Tn);
mcs=FN([find(strcmp(FN,'H039')):end-1]);

for k=1:length(mcs)
  foo.(mcs{k})=sum([Tn.(mcs{k})]);
  if ~isfield(MC,mcs{k})
    MC.(mcs{k})=foo.(mcs{k});
  else
    MC.(mcs{k})=MC.(mcs{k})+foo.(mcs{k});
  end
end
MC.(['WC_' num2str(wc)])=foo;
MC.Total=MC.Total+foo.Total;

  
function H=mdhaul(H,Tna,wc)
foo.TxStation = Tna.TxIn;
foo.TxLosses = Tna.TxLosses;
foo.Direct = Tna.DispGAL - Tna.TxIn;
if ~isfield(H,'Direct') H.Direct=0; end
if ~isfield(H,'TxStation') H.TxStation=0; end
if ~isfield(H,'TxLosses') H.TxLosses=0; end
H.Direct=H.Direct+foo.Direct;
H.TxStation=H.TxStation+foo.TxStation;
H.TxLosses=H.TxLosses+foo.TxLosses;
H.(['WC_' num2str(wc)])=foo;


% function s=scalestruct(s,fact)
% FN=fieldnames(s);
% for i=1:length(FN)
%   if isstruct(s.(FN{i}))
%     s.(FN{i})=scalestruct(s.(FN{i}),fact);
%   elseif isnumeric(s.(FN{i}))
%     s.(FN{i})=s.(FN{i})*fact;
%   else
%     % nothing to do
%   end
% end
