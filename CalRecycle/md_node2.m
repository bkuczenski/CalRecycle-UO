function [Tn,MD]=md_node2(year,wastecode,varargin)
% function [Tn,MD]=md_node2(year,wc)
%
% Processes a set of DTSC manifest files into a mass balance over terminal nodes
% (stored in Tn) and partition the manifest list with respect to travel through
% transfer stations.
%
% Second attempt (first attempt was md_node.m)
%
% Preprocess MD and TSDF data.
% Canonical facility list comes from TSDF- MD gets cleaned up so bad TSDF_EPA_IDs
% are mapped to their most likely correct versions in TSDF (maximum string
% distance of 2).
%
% Then go through the list of facilities and, based on inspection of the mass
% balance, make a determination as to:
% (1) the type of facility: G, T, P
% (2) the grouping of inflows: 
%
% Below considers only flows with method H039, H141, and unknown. and H020 bc we
% don't trust veolia.  Flows with all other method codes are considered terminal.
% 
% If the facility inflows (excl self transfers) are 0, it's a
% generator. 
% If the facility has nonzero inflows, but outflows > inflows, it's a
% consolidator.
% If the facility has nonzero inflows and 0.8*inflows < outflows < inflows, it's a 
% transfer station
% if outflows < 0.8*inflows, it's a processor.
% 
% Self-transfers are interpreted as consolidated generation.




yy=num2str(year);
wc=num2str(wastecode);

if 0;%wastecode==222
  do_sanity_check=true;
else
  do_sanity_check=false;
end
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
MD=[];

%% ----------------------------------------
% First, read and clean up input data


tanner_prefix=['../HWTS/Tanner' yy '/'];
tanner_suffix=['_' yy '_' wc];

savefile=['MD-node2' tanner_suffix '.mat'];
saveTnfile=['MD-Tn2' tanner_suffix '.mat'];

if exist(savefile)
  fprintf(1,'%s\n','Loading progress')
  ss=load(savefile);  
  
  if force | ~isfield(ss.MD,'Tn')
    fprintf(1,'Forcibly deleting Tn file and rebuilding:\n')
    fprintf(1,'%s\n',saveTnfile)
    delete(saveTnfile)
    TSDF=ss.MD.(['TSDF' tanner_suffix]);
    MD=ss.MD.(['Q' tanner_suffix]);
  else
    Tn=ss.MD.Tn;
    MD=ss.MD.(['Q' tanner_suffix]);
    return
  end
end


if isempty(MD)
  % initialize
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
  
  Ts=accum(TSDF,'mdcad',{'','',','});
  % TTx=accum(TxSt,'mddadaa','');
  
  % correct spurious TSDF_EPA_IDs in MD
  disp('Looking up spurious TSDF_EPA_IDs')
  [~,IDM]=flookup(MD,'TSDF_EPA_ID','FAC_NAME');
  NM=rmfield(MD(~IDM),{'GEN_EPA_ID','GEN_CNTY','TSDF_CNTY','WASTE_STATE_CODE', ...
                      'METH_CODE',TONS});
  disp('Correcting spurious TSDF_EPA_IDs with bestmatch valid IDs in current year')
  NM=vlookup(NM,'TSDF_EPA_ID',Ts,'TSDF_BESTMATCH','TSDF_BESTMATCH','strdist2');
  nmbest={NM.TSDF_BESTMATCH};
  [MD(~IDM).TSDF_EPA_ID]=deal(nmbest{:});
  disp('done.  Saving progress.')
  ss.MD.(['Q' tanner_suffix])=MD;
  ss.MD.(['TSDF' tanner_suffix])=TSDF;
  save(savefile,'-struct','ss');
else
  TitleBlock={  'Terminal Nodes in DTSC Manifest Data',
                ['Year ' yy '; Waste Code ' wc],
                ['Orig Units: ' ss.MD.OrigUnits ],
                ['Conversion Factor: ' ss.MD.Conv ],
                ['Display Units: ' ss.MD.ConvUnits],
                datestr(now)};
  
  disp(char(TitleBlock{:}))

  TONS='GAL';
  DispTONS='DispGAL';
  Ts=accum(TSDF,'mdcad',{'','',','});
end
  




%% ----------------------------------------
% OK GO

disp('Computing imports')
Imports=accum(filter(MD,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},...
                                       '^CA',{1,0}),'ddmddda','Im');

ImTONS=['Im' TONS];
ss.MD.ImportToCA=getfield(accum(Imports,'da',''),ImTONS);


% First, group MD into definitely terminal flows and ambiguous flows

% prepare to compute GTs
%% gt is a logical index of flows originating in GT: the GEN can be found in Ts 
disp('Finding transfer stations')
[~,gt]=vlookup(MD,'GEN_EPA_ID',Ts,'TSDF_BESTMATCH','TSDF_BESTMATCH');
% isolate self-transfers
st=strcmp({MD.GEN_EPA_ID},{MD.TSDF_EPA_ID});
st=st(:);
gt = gt & ~st; % exclude self-transfers from TxOut

% isolate Gen Tons
GTs=accum(MD(gt),'mddddda','Gen');
GenTONS=['Gen' TONS];


[MDt,term]=filter(MD,'METH_CODE',{@isempty,@regexp},...
                  {'','^H(039)|(141)$'},{1,1}); % includes terminal self transfers
MDt=accum(MDt,'ddmddma','');
Tdisp=accum(MDt,'mdad','');
term=term(:,end);

disp('Finding self-transfers')
SELF=accum(MD(st),'mddddda','Self');
SelfTONS=['Self' TONS];
SELF=moddata(SELF,SelfTONS,@floor); % includes terminal self transfers

aSELF=accum(MD(~term & st),'mddddda','aSelf');
aSelfTONS=['aSelf' TONS];
aSELF=moddata(aSELF,aSelfTONS,@floor); % excludes terminal self transfers

MDa=accum(MD(~term & ~st),'ddmdmda',''); % totals ambig flows by destination

disp('Building Terminal Node table')

if isempty(SELF)
  EE=unique({MDt.TSDF_EPA_ID MDa.TSDF_EPA_ID});
else
  EE=unique({MDt.TSDF_EPA_ID MDa.TSDF_EPA_ID SELF.GEN_EPA_ID});
end
Tn=struct('TSDF_EPA_ID',EE,...
          'Year',year,'WASTE_STATE_CODE',wc);

Tn=mvfield(vlookup(Tn,'TSDF_EPA_ID',Imports,'TSDF_EPA_ID',ImTONS,'zero'),ImTONS,'Import');

Tn=mvfield(vlookup(Tn,'TSDF_EPA_ID',Tdisp,'TSDF_EPA_ID',TONS,'zero'),TONS,DispTONS);
Tn=vlookup(Tn,'TSDF_EPA_ID',SELF,'GEN_EPA_ID',SelfTONS,'zero'); % includes
                                                                % terminal sts
Tn=vlookup(Tn,'TSDF_EPA_ID',aSELF,'GEN_EPA_ID',aSelfTONS,'zero'); % excludes
                                                                % terminal sts
Tn=mvfield(vlookup(Tn,'TSDF_EPA_ID',MDa,'TSDF_EPA_ID',TONS,'zero'),TONS,'TxIn');

Tn=mvfield(vlookup(Tn,'TSDF_EPA_ID',GTs,'GEN_EPA_ID',GenTONS,'zero'),GenTONS,'TxOut');

% it's only the ambiguous entries that need attention.  Objective is to enumerate
% total generation and total disposition.
%
% Over ambiguous flows: add up total inputs and total outputs.  Make the above
% comparison to classify as G, C, Tx, P.
% 
% In = total ambig inflows (excluding self-transfers)
% Out = total outflows (excluding self-transfers)
% Self = self-transfers (including terminal self transfers)
% Term = terminal flows (including terminal self transfers)
%
% If inflows (excl self transfers) are 0, it's a generator. 
% Gen = max(Out, Self).  Disp = Term.  Losses = Gen - Out
%
% If nonzero inflows, but outflows > inflows, it's a consolidator.
% Gen = max(Out - In, Self).  Disp = Term.  Losses = Gen - Out
% 
% If nonzero inflows and 0.8*inflows < outflows < inflows, it's a transfer station
% Gen = Self.  Disp = Term.  Losses = In + Self - Out.
%
% if outflows < 0.8*inflows, it's a processor.  Create an H039 record in MDt.
% H039 = In + Self - Out
% Gen = Self.  Disp = Term + H039.  Losses = 0;
% 

disp('Running mass balances')
for i=1:length(Tn)
  In = Tn(i).TxIn;
  Out = Tn(i).TxOut;
  Self = Tn(i).(SelfTONS);
  aSelf = Tn(i).(aSelfTONS);
  Term = Tn(i).(DispTONS);
  C_s=['-' Tn(i).TSDF_EPA_ID(1:2)];
  if Out == 0 % strict processor
    Tn(i).Class=[ 'P' C_s];
    H039 = In + aSelf;
    Tn(i).(GenTONS) = Self;
    Tn(i).(DispTONS) = Term + H039;
    MDt=add039(MDt,Tn(i).TSDF_EPA_ID,H039);
    Tn(i).TxLosses=0;
  elseif In+aSelf == 0 % strict generator
    Tn(i).Class=['G' C_s];
    Tn(i).(GenTONS) = max([Out,Self]);
    Tn(i).TxLosses = max([0,Tn(i).(GenTONS) - Term - Out]);
  elseif Out > In+aSelf % consolidator
    Tn(i).Class=['C' C_s];
    Tn(i).(GenTONS) = max([Out - In, Self]);
    Tn(i).TxLosses = max([0,Tn(i).(GenTONS) - Term - Out]);
  elseif Out > 0.8*(In+aSelf) % TxStn
    Tn(i).Class=['Tx' C_s];
    Tn(i).(GenTONS) = Self;
    Tn(i).TxLosses = In + aSelf - Out;
  else% Out < 0.8*In % Processor
    Tn(i).Class=['P' C_s];
    H039 = In + aSelf - Out;
    Tn(i).(GenTONS) = Self;
    Tn(i).(DispTONS) = Term + H039;
    MDt=add039(MDt,Tn(i).TSDF_EPA_ID,H039);
    Tn(i).TxLosses=0;
  end
end


if do_sanity_check
  disp('Tn sanity check')
  keyboard
end

% now we want to dump the self-transfers in favor of generation
Tn=rmfield(Tn,{SelfTONS,aSelfTONS});
nflows=length(fieldnames(Tn));


% outputs: we pick the method codes to measure; 
% do: H039, H050, H061, H132, H135, other/unknown



disp('pulling meth_code totals')

ByMeth=sort(accum(MDt,'dmad',''),2,'descend');
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
  Q_list=filter(MDt,'TSDF_EPA_ID',{@strcmp},Tn(i).TSDF_EPA_ID);
  if isempty(Q_list)
    for j=1:length(H_list)
      Tn(i).(H_list{j})=0;
    end
  else
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
end
nf=length(fieldnames(Tn));
Tn = orderfields( Tn, [3 nflows-1 4:(nflows-3) nflows 1 2 nflows-2 (nflows+1):nf]);

%and I think that's it


ss.MD.Tn=Tn;
%ss.MD.group_a=group_a;
%ss.MD.group_b=group_b;
%ss.MD.group_c=group_c;
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


% ---------------------------------------------
function MDt=add039(MDt,EPAID,Amt)
FN=fieldnames(MDt);
MD_add=MDt(1);
MD_add.(FN{1})=EPAID;
MD_add.(FN{2})='H039';
MD_add.(FN{3})=Amt;
MD_add.(FN{4})=1;

MDt=[MDt;MD_add];
