function [Tn,MD,group_a,group_b,group_c]=md_node(year,wastecode,varargin)
% function [Tn,MD,group_a,group_b,group_c]=crmfa(year,wc)
%
% Processes a set of DTSC manifest files into a mass balance over terminal nodes
% (stored in Tn) and partition the manifest list with respect to travel through
% transfer stations.
%
% Classify each manifest record in group A, B, or C:
%
% A: straight GEN -> TSDF
% B: GEN -> Tx, nonterminal
% C: Tx -> TSDF, terminal
%
% For each EPAID we need to determine its mass balance characteristics: its
% generation and its (disposition+losses).  In order to do that, classify each
% EPAID as G, T, or G+T on the basis of whether it sources and/or sinks
% manifests. 
% 
% Bad GEN_EPA_IDs will wind up being interpreted as Gs in this case (2010 had
% only 3.7 kt of these, so negligible).
%
% Straight Gs -- generation only -- are a partial record of UO generated.
%
% Straight Ts -- TSDF only -- are a partial record of UO disposed.
%
% G+T are the trouble group- there are 54 of these (very close to the number in
% the CalRecycle data).  Flows through G+T nodes are complicated because:
%  - a G+T could be reporting as a consolidated generator
%  - a G+T could be disposing of some oil it receives and transfering other
%  - a G+T could be disposing of oil it received under H141 (transfer)
%
% FIrst task: come up with a list of G+Ts and look at them in detail.  First, just
% DTSC data; then add CalRecycle data too.
%
% arguments:
%
%  'print' - print Tn to csv with named facilities

% cr_suffix=[ '_' num2str(year)];
% if nargin<3
%   results_file=['CRMFA' cr_suffix '.mat'];
% end

yy=num2str(year);
wc=num2str(wastecode);

printcsv=false;
force=false;
selected_hlist=false;

while ~isempty(varargin)
  if ischar(varargin{1})
    switch varargin{1}(1:3)
      case 'pri'
        printcsv=true;
      case 'for'
        force=true;
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


global FACILITIES
if isempty(FACILITIES)
  disp('No Facilities Database.  Attempting to load..')
  ff=check_file('Facilities.mat');
  load(ff);
end

EPAID_DEST_UNKNOWN='CA9999999999';
EPAID_SRC_UNKNOWN='CA0000000000';

%% ----------------------------------------
% First, read and clean up input data


tanner_prefix=['../HWTS/Tanner' yy '/'];
tanner_suffix=['_' yy '_' wc];

savefile=['MD-node' tanner_suffix '.mat'];
saveTnfile=['MD-Tn' tanner_suffix '.mat'];

if exist(savefile)
  if force
    fprintf(1,'Forcibly deleting save files and rebuilding:\n')
    fprintf(1,'%s\n',savefile,saveTnfile)
    delete(savefile)
    delete(saveTnfile)
  else
    load(savefile);  

    Tn=MD.Tn;
    group_a=MD.group_a;
    group_b=MD.group_b;
    group_c=MD.group_c;
    MD=MD.(['Q' tanner_suffix]);
    return
  end
end



DAT=load([tanner_prefix 'MD' tanner_suffix '.mat']);
MD=getfield(DAT,['MD' tanner_suffix]);
MD=MD(:);
if year<2007
  MD=meth_correct(MD,1);
else
  MD=meth_correct(MD);
end

[~,I]=filter(MD,'GEN_EPA_ID',{@isempty},[]);
[MD(I).GEN_EPA_ID]=deal(EPAID_SRC_UNKNOWN);
[~,I]=filter(MD,'TSDF_EPA_ID',{@isempty},[]);
[MD(I).TSDF_EPA_ID]=deal(EPAID_DEST_UNKNOWN);
MD=MD(~isnan([MD.TONS])); % drop NaNs

DAT=load([tanner_prefix 'TSDF' tanner_suffix '.mat']);
TSDF=getfield(DAT,['TSDF' tanner_suffix]);
if year<2007
  TSDF=meth_correct(TSDF,1);
else
  TSDF=meth_correct(TSDF);
end

[~,I]=filter(TSDF,'TSDF_BESTMATCH',{@isempty},[]);
[TSDF(I).TSDF_BESTMATCH]=deal(EPAID_DEST_UNKNOWN);
TSDF=mvfield(TSDF,'Accum__TONS','DispTONS');


% DAT=load([tanner_prefix 'TxSt' tanner_suffix '.mat']);
% TxSt=getfield(DAT,['TxSt' tanner_suffix]);

% [~,I]=filter(TxSt,'TSDF_BESTMATCH',{@isempty},[]);
% [TxSt(I).TSDF_BESTMATCH]=deal(EPAID_DEST_UNKNOWN);


%UE=unique({MD(:).GEN_EPA_ID; MD(:).TSDF_EPA_ID});

%% ----------------------------------------
% Unit Conversion

% ss=savefile

ss.MD.Year=year;
ss.MD.WasteCode=wastecode;
ss.MD.OrigUnits='Metric Tons';

ss.MD.Conv='301.85 Gal/t (875 g/cm3)';
ss.MD.ConvFactor=301.85;
ss.MD.ConvUnits='Gallons'

TONS='GAL';
DispTONS='DispGAL';

disp('Converting t to Gal; display units in Gal')

TitleBlock={  'Terminal Nodes in DTSC Manifest Data',
              ['Year ' yy '; Waste Code ' wc],
              ['Orig Units: ' ss.MD.OrigUnits ],
              ['Conversion Factor: ' ss.MD.Conv ],
              ['Display Units: ' ss.MD.ConvUnits],
              datestr(now)};

disp(char(TitleBlock{:}))

MD=mvfield(MD,'TONS',TONS);
MD=fieldop(MD,TONS,['#' TONS ' * ' num2str(ss.MD.ConvFactor) ]);
MD=moddata(MD,TONS,@floor);

TSDF=mvfield(TSDF,'DispTONS',DispTONS);
TSDF=fieldop(TSDF,DispTONS,['#' DispTONS ' * ' num2str(ss.MD.ConvFactor) ]);
TSDF=moddata(TSDF,DispTONS,@floor);

%% ----------------------------------------
% OK GO

ss.MD.ImportToCA=getfield(accum(filter(MD,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},...
                                       '^CA',{1,0}),'dddddda',''),TONS);

Ts=accum(TSDF,'mdcad',{'','',','});
% TTx=accum(TxSt,'mddadaa','');

% correct spurious TSDF_EPA_IDs in MD
disp('Correcting spurious TSDF_EPA_IDs with bestmatch valid IDs in current year')
[~,IDM]=flookup(MD,'TSDF_EPA_ID','FAC_NAME');
NM=rmfield(MD(~IDM),{'GEN_EPA_ID','GEN_CNTY','TSDF_CNTY','WASTE_STATE_CODE', ...
                    'METH_CODE',TONS});
NM=vlookup(NM,'TSDF_EPA_ID',Ts,'TSDF_BESTMATCH','TSDF_BESTMATCH','strdist2');
nmbest={NM.TSDF_BESTMATCH};
[MD(~IDM).TSDF_EPA_ID]=deal(nmbest{:});


%% gt is a logical index of flows originating in GT: the GEN can be found in Ts 
[~,gt]=vlookup(MD,'GEN_EPA_ID',Ts,'TSDF_BESTMATCH','TSDF_BESTMATCH');
%% st is a logical index of self-transfers
st=strcmp({MD.GEN_EPA_ID},{MD.TSDF_EPA_ID});
st=st(:);
% we make an executive decision to only include gt self-transfers
st = st & gt;
gt = gt & ~st;

% self-transfers we're interpreting as consolidated generators. let's see if it
% bears out: yes.  case in point: CRANE'S WASTE OIL CAD980813950
% so we don't want these counted as Generated flows.  Since our DispTONS was
% computed from TSDF, it will still be included there.

GTs=accum(MD(gt),'mddddda','Gen');

GenTONS=['Gen' TONS];

%% Group B flows are flows to GT with meth code H141
MD=vlookup(MD,'TSDF_EPA_ID',GTs,'GEN_EPA_ID',GenTONS,'bla'); % first, flag
                                                                  % all transfers
                                                                  % to GT
MD=moddata(MD,GenTONS,@sign);
MD=mvfield(MD,GenTONS,'to_GT'); % if empty, the EPAID is not a generator

%% group_b is a logical index of nonterminal flows to GTs
disp('Isolating Group B flows')
[~,group_b]=filter(MD,{'to_GT','METH_CODE'},{@eq,@strcmp},{1,'H141'});
group_b=group_b(:,end);

MD_B=accum(MD( group_b ),'ddmddda','H141');
if isempty(MD_B)
  keyboard
end
H141TONS=['H141' TONS];
GTs = vlookup(GTs,'GEN_EPA_ID',MD_B,'TSDF_EPA_ID',H141TONS,'zero');

GTs=vlookup(GTs,'GEN_EPA_ID',Ts,'TSDF_BESTMATCH',DispTONS,'zero');
GTs=sort(GTs,DispTONS,'descend');
GTs=rmfield(GTs,'Count');

SELF=accum(MD(st),'mddddda','Self');
SelfTONS=['Self' TONS];
SELF=moddata(SELF,SelfTONS,@floor);

% now, add balancing terms to either side
in=[GTs.(H141TONS)];
out=[GTs.(GenTONS)];

myst_out=zeros(size(out));
myst_in=zeros(size(in));

myst_in(out>in)=floor(out(out>in)-in(out>in));
myst_out(in>out)=floor(in(in>out)-out(in>out));

GTs=assign(GTs,myst_in);
GTs=assign(GTs,myst_out);
if isempty(SELF)
  [GTs.(SelfTONS)]=deal(0);
else
  GTs=vlookup(GTs,'GEN_EPA_ID',SELF,'GEN_EPA_ID',SelfTONS,'zero');
end
%GTs=vlookup(GTs,'GEN_EPA_ID',Ts,'TSDF_BESTMATCH','METH_CODE','blank');

GTs=orderfields(GTs,[5 4 3 7  1 2 6]);

%% now I need to identify group B and C MD records.  Group B are anything that
%arrives at a GT that gets passed on.  So we should just say any H141 destined for
%a GT.  

%% gt_disp is a logical index of terminal flows to GTs (i.e. the footprint of GT
%  in T) 
disp('finding terminal disposal flows')
[~,gt_disp]=filter(MD,{'to_GT','METH_CODE'},{@eq,@strcmp},{1,'H141'},{0,1});
gt_disp=gt_disp(:,end);

%% gt & gt_disp = flows from GT->GT where second GT is acting as T    - 76 in 2008
%% gt & group_b = flows from GT->GT where the first GT is acting as G - 54 in 2008
%% remainder of gt are flows to T in both group a and group c         - 152 in 2008 

%% st is self-transfers: two cases: G->Tx (group b) or G|Tx->T (group c).  Tx->Tx
%% self transfer doesn't make sense.  so st which appear to not be in group_b or
%% gt_disp actually belong in one or the other.  Put them in gt_disp under the
%% assumption that facilities which receive H141 will not false-negative on the
%GTs vlookup (i.e. they will receive it from not solely themselves).
gt_disp=gt_disp | ( st & ~group_b);

%% st & gt_disp = self-transfers to disposition (assume group a) - 22 in 2008
%% st & group_b = self-transfers, GT as generator                - 17 in 2008

%% also keep in mind there are erroneous / omitted method
%% codes / EPAIDs / etc.  so it's ultimately imperfect.

%% for those sets where group a vs group c membership is ambiguous- it is
%% impossible to say.  But in 2008 this is 190 kt, so it must be studied.  add it
%to the table!

gt_ac = gt & ~group_b;% & ~gt_disp; % ambiguous flows

% ok, so for each facility where the output is > 1.05* input, then it's likely the
% output came from generation.  call it group a.  otherwise, group c
%
% so how do we get there from here?  
%
% decision goes by facility, not by flow.  So to identify group c, find the flows
% that are in gt_ac that belong to facilities meeting the criterion.
disp('Isolating Group C flows')
GTC = GTs( out <= 1.05*in );
[~,super_c]=vlookup(MD,'GEN_EPA_ID',GTC,'GEN_EPA_ID',GenTONS);
%% group_c is a logical index of terminal flows from GTs
group_c = (super_c & gt_ac); 
group_a = ~group_b & ~group_c;



%% ----------------------------------------
disp('Correcting Group A')
% because the decision is on a facility and not a flow basis (because we don't
% have actual flows), we may need to make corrections.  Observationally, in most 
% group c facilities the ambiguous tonnage is clearly all group C; but for group a
% facilities any group b input (which properly terminates in group c) will get
% added into group a.
%
% use METH_CODE Y141 'Transfer Station Adjustment' to re-classify a flow magnitude 
% equal to H141 inputs from group a to group c.
GTA = GTs( out > 1.05*in );
cor_t=MD([]);

% build the correction records
[cor_t(1:length(GTA)).GEN_EPA_ID]=GTA.GEN_EPA_ID;
[cor_t(1:length(GTA)).TSDF_EPA_ID]=deal('');
[cor_t(1:length(GTA)).TSDF_CNTY]=deal(0);
cor_t=vlookup(cor_t,'GEN_EPA_ID',MD,'GEN_EPA_ID','GEN_CNTY');
[cor_t(1:length(GTA)).(TONS)]=GTA.(H141TONS);
[cor_t(1:length(GTA)).METH_CODE]=deal('Y141');
[cor_t(1:length(GTA)).WASTE_STATE_CODE]=deal(wc);
cor_t=cor_t(:);

cor_c=logical(ones(size(cor_t)));

% group c is increased; group a is decreased - stack the two sets of corrections
cor_t=[cor_t; moddata(cor_t,TONS,@(x)(-x))];
cor_c=[cor_c; ~cor_c];
cor_a=~cor_c;



MD=[MD;cor_t];
group_c = [ group_c ; cor_c ];
group_a = [ group_a ; cor_a ];
group_b = [ group_b ; logical(zeros(size(cor_c)))];
% still need st
% no we don't st=[st; logical(zeros(size(cor_c)))];



%% ----------------------------------------
disp('Bulding mass balance')
% now build the mass balance matrix - on terminal nodes
Tdisp = accum(MD( group_a | group_c ),'ddmddma','');

Tn = accum(MD( group_a | group_c ),'ddmdmda','Disp');
Tn = rmfield(Tn,'Count');
Tn = orderfields(Tn,[2 1 3]);
Tn(cellfun(@isempty,{Tn(:).TSDF_EPA_ID}))=[];

% inputs: we want just total inbound (from above) and self-transfers, and losses
if isempty(SELF)
  [Tn.(SelfTONS)] = deal(0);
else
  Tn = vlookup(Tn,'TSDF_EPA_ID',SELF,'GEN_EPA_ID',SelfTONS,'zero');
end
Tn = vlookup(Tn,'TSDF_EPA_ID',GTs,'GEN_EPA_ID',H141TONS,'zero');
Tn = mvfield(Tn,H141TONS,'TxIn');
Tn = vlookup(Tn,'TSDF_EPA_ID',GTs,'GEN_EPA_ID',GenTONS,'zero');
Tn = mvfield(Tn,GenTONS,'TxOut');
Tn = vlookup(Tn,'TSDF_EPA_ID',GTs,'GEN_EPA_ID','myst_out','zero');
Tn = mvfield(Tn,'myst_out','TxLosses');

nflows=length(fieldnames(Tn));

% outputs: we pick the method codes to measure; 
% do: H039, H050, H061, H132, H135, other/unknown



disp('pulling meth_code totals')

ByMeth=sort(accum(Tdisp,'dmad',''),2,'descend');
ByMeth=filter(ByMeth,'METH_CODE',{@regexp},'[A-Z]');
ByMeth=meth_lookup(ByMeth)

show(ByMeth)

if selected_hlist
  H_list={'H039','H050','H061','H132','H135'};
else
  H_list={ByMeth(:).METH_CODE};
  H_list(cellfun(@isempty,H_list))={'unknown'};
  H_list=H_list(1:min([length(ByMeth) find([ByMeth.(TONS)]/ByMeth(1).(TONS) < 5e-4)]));
end

for i=1:length(Tn)
  Q_list=filter(Tdisp,'TSDF_EPA_ID',{@strcmp},Tn(i).TSDF_EPA_ID);
  for j=1:length(H_list)
    if strcmp(H_list{j},'unknown')
      mm=cellfun(@isempty,({Q_list(:).METH_CODE}));
    else
      mm=strcmp({Q_list.METH_CODE},H_list{j});
    end
    try
      Tn(i).(H_list{j})=sum([Q_list(mm).(TONS)]);
    catch
      disp(['H_list item: ' H_list{j}])
      keyboard
    end
    Q_list=Q_list(~mm);
  end
  if ~isempty(Q_list)
    Tn(i).OtherUnknown=sum([Q_list.(TONS)]);
    Tn(i).Others=getfield(accum(Q_list,'dcdd',{'','',','}),'METH_CODE');
  end
end
nf=length(fieldnames(Tn));
Tn = orderfields( Tn, [1 3:nflows 2 (nflows+1):nf]);

%and I think that's it
%keyboard


ss.MD.(['Q' tanner_suffix])=MD;
ss.MD.Tn=Tn;
ss.MD.group_a=group_a;
ss.MD.group_b=group_b;
ss.MD.group_c=group_c;
save(savefile,'-struct','ss')

svv.(['Tn' tanner_suffix])=Tn;
svv.(['TSDF' tanner_suffix])=TSDF;
save(saveTnfile,'-struct','svv')

if printcsv
  csvfile=['MD-node' tanner_suffix '.csv'];
  if exist(csvfile)
    disp('Deleting csvfile')
    delete(csvfile);
  end
  
  show(sort(flookup(Tn,'TSDF_EPA_ID','FAC_NAME','inplace'),2,'descend'),'',...
       csvfile,',*',TitleBlock)
  
  show(ByMeth,'',csvfile,',*')

  
  show(sort(flookup(Tn,'TSDF_EPA_ID','FAC_NAME','inplace'),2,'descend'))
end


