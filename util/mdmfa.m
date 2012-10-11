function [R,MD]=mdmfa(manfile,year,wastecode,results_file)
% function MD=mdmfa(manfile,year,wastecode)
%
% Creates an MFA dataset from Tanner Report data.  Works accretively, saving its
% progress, so that work does not have to be repeated.
%%
%%
%  generates a list of saved data records based on manifest datasets herein
% described. Each has the 'tanner suffix' which is '_yyyy_ccc' for year and
% catcode, eg MD_2010_221.  Saves the files:
%
% MD        all manifests
% TSDF  facilities which receive, ex H141
% TxSt  facilities that receive H141, and their generation
%
%%
%
% Why is this so hard for me to wrap my head around?


VERSION='0.12'
INTERACTIVE=false;

% 0.12 - 08-13 Remedy H141 regexp for ambiguous 2006 year; added ifstr2num
% 0.11 - 07-17 Repair double-counting adjustment with H141 shortfall / X141
% 0.10 - 07-11 historical tanner data.. through 2004?
% 0.09 - 06-25 pre-stakeholder meeting; distrib to DK, Ev, SK, API etc
% 0.01 - first draft; to DTSC

if ~exist('Tanner.mat','file')
  create_tanner_mat
end
load Tanner.mat

disp('What do I want to do with all of this?')
disp(' show() to file and print out title blocks')


% manage facility list-- this should be intelligent so as to merge the current
% year with later years 
%% on second thought, this should be externally managed, and should not be
%subsumed into this function.  The Facility function should: screen out blank
%entries, screen out invalid EPAIDs, merge the current dated list with the master
%list using setdiff or similar.
%% but for now, assume that Facilities.mat contains up-to-date information

% now: we read in the manifest data.  filter on waste code

% manifest_read assumes wastecode is a string, not a number.  regexp is quicker
% than str2double.
if isnumeric(wastecode) wastecode=num2str(floor(wastecode)); end
tanner_suffix=[ '_' num2str(year) '_' wastecode];

mdfile=['MD' tanner_suffix];

tsdffile=['TSDF' tanner_suffix];
txstfile=['TxSt' tanner_suffix];
genimportfile=['GenImport' tanner_suffix];
transfile=['Trans' tanner_suffix];

if nargin<4
  results_file=['MDMFA' tanner_suffix '.txt'];
end


switch year
  % note- q is obsolete
  case 2001
    manifest_read={'s','n','s','n','s','','s','n'};
    WASTE_STATE_CODE='WASTE_STATE_CODE';
    TSDF_CNTY='DISP_CNTY';
  case 2010
    manifest_read={'s','n','s','n','','','s','s','n'};
    WASTE_STATE_CODE='WASTE_STATE_CODE';
    TSDF_CNTY='TSDF_CNTY';
  case 2007
    manifest_read={'qs','qn','qs','qn','qs','qs','n'};
    WASTE_STATE_CODE='WASTE_STATE_CODE';
    TSDF_CNTY='DISP_CNTY';
  case 2006
    manifest_read={'s','n','s','n','s','s','n'};
    WASTE_STATE_CODE='CAT_CODE';
    TSDF_CNTY='DISP_CNTY';
  otherwise
    %% 1996 case: line 81982 has a typo
    % case 2011,2009,2008,2005,2004,2003,2002,2000,1999,1998,1997,1996,1995,1994,1993
    manifest_read={'s','n','s','n','s','s','n'};
    WASTE_STATE_CODE='CAT_CODE';
    TSDF_CNTY='DISP_CNTY';
end

if year>2006
  H141_REGEXP='^H14';
elseif year==2006
  H141_REGEXP='^H((01)|(14))';
else
  H141_REGEXP='^H01';
end


if ~exist([mdfile '.mat'],'file')
  disp('Reading manifest data')
  MD=read_dat(manfile,',',manifest_read,...
              struct('Field',WASTE_STATE_CODE,'Test',{@regexp},'Pattern',wastecode));
  if year==2011
    % need to correct for erroneous TSDF_CNTY entry through flookup 
    MD=rmfield(MD,TSDF_CNTY);
    [MD,M]=flookup(MD,'TSDF_EPA_ID','FAC_CNTY');
    MD=moddata(MD,'FAC_CNTY',@ifstr2num);
    MD=orderfields(MD,[1 2 3 7 4 5 6]);
  end
  if ~isfield(MD,'WASTE_STATE_CODE')
    MD=mvfield(MD,WASTE_STATE_CODE,'WASTE_STATE_CODE');
  end
  if ~isfield(MD,'TSDF_CNTY')
    MD=mvfield(MD,4,'TSDF_CNTY');
  end
  if ~isfield(MD,'TSDF_EPA_ID')
    MD=mvfield(MD,3,'TSDF_EPA_ID');
  end
  if ~isfield(MD,'TONS')
    MD=mvfield(MD,7,'TONS');
  end
  % ensure field order is correct
  if year==2011
    try
      MD=orderfields(MD,{'GEN_EPA_ID',
                         'GEN_CNTY',
                         'TSDF_EPA_ID',
                         'TSDF_CNTY',
                         'WASTE_STATE_CODE',
                         'METH_CODE',
                         'TONS'}); % this will error if something is wrong
    catch
      disp('Ordering fields messed up')
      keyboard
    end
  end
  disp('Converting to metric tons (all data fields)')
  MD=moddata(MD,'TONS',@(x)(x * 0.9072 )); % metric tons
  %keyboard
  eval([mdfile '=MD;']);
  save([mdfile '.mat'],mdfile);
else
  disp(['Loading manifest data from ' mdfile])
  load(mdfile)
  eval(['MD=' mdfile ';']);
end
clear(mdfile) % MD is our content
% disp('Deblanking waste code') %% done 
% MD=moddata(MD,'WASTE_STATE_CODE',@(x)(num2str(str2num(x))))

global FACILITIES
if isempty(FACILITIES)
  disp('No Facilities Database.  Attempting to load..')
  ff=check_file('Facilities.mat');
  load(ff);
end


%%Step 0: create a concise list of TSDFs and clean it up
% MD is : gen, gencty, TSDF, TSDFcty, WC, MC, tons

%% operation: repair damaged or misentered EPAIDs using string distance
% null accumulate on one field according to EPAID regexp.  
% separate non-matching records; cull original to positive sort.
% vlookup into the positive sort to identify matches.  this introduces errors 
% because erroneous entries not represented in the positive sort will get
% misidentified; but these are (presumably) rare and can be neglected
%
% future solution: switch to new strdist and limit matches to a 2-char threshold
% (having the accreted Facilities list will probably rule out a lot of
% correctly-entered IDs.  quick perusal of TSDF_neg is positive.)

% function R=repair(D,field,correct)
% This function attempts to repair incorrect entries by identifying the nearest
% match among correct records.
% used to repair inaccurately entered EPAIDs, among others.  Uses Levenshtein
% distance, so it only works for strings that are structurally close to one
% another. 


if ~exist([tsdffile '.mat'],'file')
  % handle dependencies:
  delete([txstfile '.mat'])
  delete([genimportfile '.mat'])
  disp('Identifying TSDFs')
  TSDF_MM=accum(MD,'ddmdmma');
  % TSDF_MM is : TSDF, WC, MC, tons, count

  %% now match EPAIDs to facility names
  TSDF=accum(TSDF_MM,'mdddd');
  % TSDF is : TSDF, count
  [TSDF,M]=flookup(TSDF,'TSDF_EPA_ID','FAC_NAME');

  TSDF_neg=TSDF(~M);
  TSDF=TSDF(M);
  if INTERACTIVE
    qqq=ifinput('Do you want to inspect the list of non-EPAID TSDFs?','no','s');
    if ~strcmp(qqq,'no')
      keyboard
    end
  else
    disp('Do you want to inspect the list of non-EPAID TSDFs? [no]')
  end
  
  %% fuzzy-match non-matching EPAIDs against matching ones.  assumption: that there
  %are no TSDF facilities that only show up as incorrectly-entered EPAIDs.  I'm
  %willing to live with lost corner cases to avoid having to fuzzy match against the 
  %entire facilities table.
  TSDF_neg=mvfield(TSDF_neg,'TSDF_EPA_ID','TSDF_BAD_ID');
  TSDF_neg=vlookup(TSDF_neg,'TSDF_BAD_ID',TSDF,'TSDF_EPA_ID','TSDF_EPA_ID', ...
                   'oldstrdist');
  % note: doing this for generators requires some serious CPU
  TSDF_neg=mvfield(TSDF_neg,'TSDF_EPA_ID','TSDF_BESTMATCH');
  % now we want to replace the bad EPAIDs with the best matches
  TSDF_MM=vlookup(TSDF_MM,'TSDF_EPA_ID',TSDF_neg,'TSDF_BAD_ID','TSDF_BESTMATCH')

  warning('Probably want to do some manual checking of this part')
  % correct EPAIDs will find no match in TSDF_neg and will be forwarded out
  % TSDF_MM is now : TSDF WC MC tons count Bestmatch
  % now we re-accumulate on BESTMATCH
  TSDF_MM=orderfields(accum(TSDF_MM,'dmmaam'),[3 1 2 4 5 6]); 
  TSDF_MM=mvfield(TSDF_MM,'Accum__Accum__TONS','Accum__TONS');
  TSDF_MM=rmfield(TSDF_MM,'Count');
  TSDF_MM=mvfield(TSDF_MM,'Accum__Count','Count')
  
  eval([tsdffile '=TSDF_MM;']);
  save(tsdffile,tsdffile,'TSDF_neg');
  disp(['Writing file ' tsdffile])
else
  disp(['Loading file ' tsdffile])
  load(tsdffile)
  eval(['TSDF_MM=' tsdffile ';']);
end
clear(tsdffile)

%% Now I want to eliminate double-counting entries by identifying facilities 
% which receive oil and treat it as H141.   
if ~exist([txstfile '.mat'],'file')
  % handle dependencies
  delete([genimportfile '.mat'])
  %remove old X141 entries
  TSDF_MM=filter(TSDF_MM,'METH_CODE',{@strcmp},'X141',1);
  TSDF_MM=TSDF_MM(:);

  disp('Identifying Tx Stations')

  
  TxSt = accum(...
      filter(TSDF_MM,{'TSDF_BESTMATCH','METH_CODE'},{@isempty,@regexp},{'',H141_REGEXP},{1,0}),...
      'mmdad');
  TxSt=mvfield(TxSt,'Accum__Accum__TONS','H141_TONS');

  
  % Vlookup on generators into this 
  % list to identify transfer stations; accum over them
  for i=1:length(TxSt)
    MyAccum=accum(filter(MD,'GEN_EPA_ID',{@regexp},TxSt(i).TSDF_BESTMATCH), ...
                  'mddddda');
    if ~isempty(MyAccum)
      TxSt(i).GEN_TONS=MyAccum.Accum__TONS;
    else
      TxSt(i).GEN_TONS=0;
    end
    % H141_TONS represents <wc> received by the facility under H141.  GEN_TONS
    % represents <wc> shipped out by the facility.  If GEN_TONS < H141_TONS,
    % then some <wc> is vanishing in the facility.
    H141_SHORT=max([0,TxSt(i).H141_TONS - TxSt(i).GEN_TONS]);
    if H141_SHORT > 0 & strcmp(TxSt(i).TSDF_BESTMATCH(1:2),'CA')
      TxSt(i).H141_SHORT=H141_SHORT;
      % append a new synthetic MM entry to describe the apparent disposition
      new_MM=struct('TSDF_BESTMATCH',TxSt(i).TSDF_BESTMATCH,'WASTE_STATE_CODE',wastecode,...
                    'METH_CODE','X141','Accum__TONS',TxSt(i).H141_SHORT,...
                    'Count',1);
      disp(['Appending X141 disposition of ' num2str(H141_SHORT) ' t to ' TxSt(i).TSDF_BESTMATCH])
      TSDF_MM=[TSDF_MM;new_MM];
    end
  end
  TxSt=orderfields(...
      vlookup(TxSt,'TSDF_BESTMATCH',MD,'TSDF_EPA_ID','TSDF_CNTY'),...
      [1 7 2 3 4 5 6]);
  eval([txstfile '=TxSt ;']);
  eval([tsdffile '=TSDF_MM ;']);
  save(txstfile,txstfile)
  disp(['Writing TxSt file ' txstfile])
  save(tsdffile,tsdffile)
  disp(['Writing updated TSDF file ' txstfile])
else
  disp('Loading TxSt')
  load(txstfile)
  eval(['TxSt=' txstfile ';']);
end
clear(txstfile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 1: Double-Counting-Adjusted generation by county, plus imports
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('%% STEP 1: Double-Counting-Adjusted generation by county')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

if ~exist([genimportfile '.mat'],'file')
  disp('Estimating Generation by County')

  GENCNTY=moddata(accum(MD,'dmddmda'),'GEN_CNTY',@ifstr2num); % don't care about method code
  [GENCNTY_CA,M]=filter(GENCNTY,{'GEN_CNTY','GEN_CNTY'},{@le,@ge},{58,1});
  M=M(:,1)&M(:,2);
  GENCNTY_out=GENCNTY(~M);
  
  TxSt_CNTY=moddata(accum(TxSt,'dmmaaaa'),'TSDF_CNTY',@ifstr2num);
  
  GENCNTY_CA=vlookup(GENCNTY_CA,'GEN_CNTY',TxSt_CNTY,'TSDF_CNTY','Accum__H141_TONS','zero');
  GENCNTY_CA=vlookup(GENCNTY_CA,'GEN_CNTY',TxSt_CNTY,'TSDF_CNTY','Accum__H141_SHORT','zero');
  
  NetTons=num2cell([GENCNTY_CA(:).Accum__TONS] ...
                   -[GENCNTY_CA(:).Accum__H141_TONS]...
                   +[GENCNTY_CA(:).Accum__H141_SHORT]);
  [GENCNTY_CA.NetTons]=deal(NetTons{:});
  
  GENCNTY_CA=sort(GENCNTY_CA,1);
  GENCNTY_CA=orderfields(...
      vlookup(GENCNTY_CA,'GEN_CNTY',Counties,'CNTY_CODE','CNTY_NAME'),...
      [8 1 2 3 5 6 7 4]);
  
  IMPORT=rmfield(accum(GENCNTY_out,'dmaa'),'Count');
  IMPORT=mvfield(IMPORT,'Accum__Count','Count');
  IMPORT=mvfield(IMPORT,'Accum__Accum__TONS','Accum__TONS');
  
  eval([genimportfile '=GENCNTY_CA ;']);
  save(genimportfile,genimportfile,'IMPORT')
  disp(['Writing GENCNTY_CA file ' genimportfile])
else
  disp('Loading GENCNTY_CA')
  load(genimportfile) % also loads IMPORT automagically
  eval(['GENCNTY_CA=' genimportfile ';']);
end
clear(genimportfile)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 2: Fate of non-double-counted oil
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('%% STEP 2: Fate of non-double-counted oil')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

[TSDF_CA,M]=filter(TSDF_MM,{'TSDF_BESTMATCH','METH_CODE'},...
                   {@regexp,@regexp},...
                   {'^CA',H141_REGEXP},{0,1});

TSDF_EXPORT=TSDF_MM(~M(:,1)); % includes txfr
TSDF_Txfr=TSDF_MM(M(:,1)&~M(:,2));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 3: Transport Distances
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('%% STEP 3: Transport Distances')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')

% do this as a gross average on a county basis
% depends only on MD

if ~exist([transfile '.mat'],'file')
  disp('Estimating transport distances')
  
  [~,MF]=filter(MD,{'GEN_CNTY','GEN_CNTY'},...
                {@ge,@le},...
                {1,58});
  imported=~MF(:,2); % don't need 'or' bc of shortcircuit eval
  [~,MF]=filter(MD,{'TSDF_CNTY','TSDF_CNTY'},...
                {@ge,@le},...
                {1,58});
  exported=~MF(:,2); % don't need 'or' bc of shortcircuit eval
  
  % imported oil is out of scope
  
  % fill this in later
  EXPORT_DIST=accum(...
      moddata(MD(exported),'TSDF_EPA_ID',...
              @(x)(subsref([x '     '],...
                           struct('type','()','subs',{{1:2}}))) ),...
      'dmmdmda'); % county of gen to state of dest
  
  INSTATE=accum(MD(~imported&~exported),'dmdmmda');
  
  INSTATE=moddata(moddata(INSTATE,'GEN_CNTY',@ifstr2num),...
                  'TSDF_CNTY',@ifstr2num);
  
  cd=check_file('CountyDistances.mat');
  load(cd);

  try
  CD=CountyDistances(...
      sub2ind(size(CountyDistances),...
              [INSTATE(:).GEN_CNTY],[INSTATE(:).TSDF_CNTY]));
  catch
    disp('CD lookup error- zero county?')
    keyboard
    CD=CountyDistances(...
        sub2ind(size(CountyDistances),...
                [INSTATE(:).GEN_CNTY],[INSTATE(:).TSDF_CNTY]));
  end
  INSTATE_Freight=CD .* [INSTATE(:).Accum__TONS];
  
  CDc=num2cell(CD);
  IFc=num2cell(INSTATE_Freight);
  
  [INSTATE.Dist]=deal(CDc{:});
  [INSTATE.Freight]=deal(IFc{:});

  eval([transfile '=INSTATE ;']);
  
  save(transfile,transfile)
  disp(['Writing Trans file ' transfile])
else
  disp('Loading Trans')
  load(transfile)
  eval(['INSTATE=' transfile ';']);
end
clear(transfile)

%% #######################################################################################
%% result tabulation
%% #######################################################################################

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STEP 4: Generate Output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')
disp('%% STEP 4: Generate Output')
disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%')


showfile=results_file;
if exist(results_file,'file')
  disp(['Deleting results file ' results_file '..'])
  delete(results_file)
end



%keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Generation, Imports

%%###### Data 0 - GEN_CA

GEN_CA=accum(GENCNTY_CA,'ddmaaaaa');

if length(GEN_CA)>1
  disp('length(GEN_CA) > 1')
  keyboard
end

GEN_CA=vlookup(GEN_CA,'WASTE_STATE_CODE',WasteCodes,'CAT_CODE','CAT_DESC');
GEN_CA=mvfield(GEN_CA,2,'STATEWIDE_GENERATED_TONS');
GEN_CA=mvfield(GEN_CA,3,'INSTATE_H141_TONS');
GEN_CA=mvfield(GEN_CA,4,'H141_SHORTFALL');
GEN_CA=mvfield(GEN_CA,5,'NetTons');
GEN_CA=mvfield(GEN_CA,6,'Record_Count');
GEN_CA=mvfield(GEN_CA,7,'CA_Counties');
GEN_CA=mvfield(GEN_CA,8,'WASTE_DESC');

WasteCode=GEN_CA.WASTE_STATE_CODE;
WasteDesc=[WasteCode ' - ' GEN_CA.WASTE_DESC];   %
TotalTons=GEN_CA.STATEWIDE_GENERATED_TONS;


%%###### Data 1 - Generation

Generation=rmfield(Counties,'COUNTY_CODE');

Generation=vlookup(Generation,'CNTY_CODE',...
                   GENCNTY_CA,'GEN_CNTY','Accum__TONS','bla');
Generation=vlookup(Generation,'CNTY_CODE',...
                   GENCNTY_CA,'GEN_CNTY','Accum__H141_TONS','bla');
Generation=vlookup(Generation,'CNTY_CODE',...
                   GENCNTY_CA,'GEN_CNTY','Accum__H141_SHORT','bla');
Generation=vlookup(Generation,'CNTY_CODE',...
                   GENCNTY_CA,'GEN_CNTY','NetTons','bla');

FN=fieldnames(Generation);

%%###### Data 2 - IMPORT

IMPORT=rmfield(IMPORT,'WASTE_STATE_CODE');

GEN_CA.Import=IMPORT.Accum__TONS;

ExTotal=accum(TSDF_EXPORT,'dmdad');
GEN_CA.Export=ExTotal.Accum__Accum__TONS;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Txfr facilities

%%###### Data 3 - Transfer Stations

cutoff=min([floor(TotalTons/300),1000]);
Transfer=rmfield(TSDF_Txfr,'WASTE_STATE_CODE');
Transfer=rmfield(Transfer,'METH_CODE');
Transfer=orderfields(flookup(Transfer,'TSDF_BESTMATCH','FAC_NAME'),[1 4 2 3]);
Transfer=mvfield(Transfer,'Accum__TONS','H141_TONS');
Transfer=vlookup(Transfer,'TSDF_BESTMATCH',TxSt,'TSDF_BESTMATCH','GEN_TONS','blank');
%Transfer=mvfield(Transfer,'TONS','GEN_TONS');
Transfer=trunc(Transfer,3,cutoff,'ddaaa')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% In-state oil by destination

%%###### Data 4 - TSDF, non-transfer

Destinations=accum(TSDF_CA,'mddaa');
Destinations=flookup(Destinations,'TSDF_BESTMATCH','FAC_NAME');
Destinations=rmfield(Destinations,'Count');
Destinations=mvfield(Destinations,2,'Accum__TONS');
Destinations=orderfields(Destinations,[1,4,2,3])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% In-state oil by disposition

%%###### Data 5 - Fate by Method Code ** MFIA RESULT

Fates=accum(TSDF_CA,'ddmaa');
if year<2006
  Fates=vlookup(Fates,'METH_CODE',Methods_old,'METH_CODE_OLD','METH_DESC');
else
  Fates=vlookup(Fates,'METH_CODE',Methods,'METH_CODE','METH_DESC');
end
Fates=rmfield(Fates,'Count');
Fates=mvfield(Fates,2,'Accum__TONS');
Fates=orderfields(Fates,[1,4,2,3])

%%%% scary implicit variable naming here! but why scary? 'Methods' is hardcoded.. 
Outputs_CA=transform(Fates,'Accum__TONS',eval(['x' wastecode]));



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%###### Data 6 - Out-of-state oil by state

ExDest_State=moddata(TSDF_EXPORT,1,...
                     @(x)(subsref([x '   '],...
                                  struct('type','()','subs',{{1:2}}))) );
ExDest_State=accum(ExDest_State,'mddaa');
ExDest_State=flookup(ExDest_State,'TSDF_BESTMATCH','FAC_NAME');
ExDest_State=rmfield(ExDest_State,'Count');
ExDest_State=mvfield(ExDest_State,1,'TSDF_STATE');
ExDest_State=mvfield(ExDest_State,2,'Accum__TONS');
ExDest_State=orderfields(ExDest_State,[1,4,2,3])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%###### Data 7 -  Out-of-state oil by destination

ExDest_TSDF=accum(TSDF_EXPORT,'mddaa');
ExDest_TSDF=flookup(ExDest_TSDF,'TSDF_BESTMATCH','FAC_NAME');
ExDest_TSDF=rmfield(ExDest_TSDF,'Count');
ExDest_TSDF=mvfield(ExDest_TSDF,2,'Accum__TONS');
ExDest_TSDF=orderfields(ExDest_TSDF,[1,4,2,3])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%###### Data 8 -  Out-of-state oil by disposition ** MFIA

ExFates=accum(TSDF_EXPORT,'ddmaa');
if year<2006
  ExFates=vlookup(ExFates,'METH_CODE',Methods_old,'METH_CODE_OLD','METH_DESC');
else
  ExFates=vlookup(ExFates,'METH_CODE',Methods,'METH_CODE','METH_DESC');
end
ExFates=rmfield(ExFates,'Count');
ExFates=mvfield(ExFates,2,'Accum__TONS');
ExFates=orderfields(ExFates,[1,4,2,3])

%%%% scary implicit variable naming here! but why scary? 'Methods' is hardcoded.. 
Outputs_Ex=transform(ExFates,'Accum__TONS',eval(['x' wastecode]));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%###### Data 9 -  In-State Freight

Freight=accum(INSTATE,'dddaaaa');
Freight=rmfield(Freight,'Count');
Freight=mvfield(Freight,1,'Accum__TONS');
Freight=mvfield(Freight,3,'Accum__Dist_km');
Freight=mvfield(Freight,4,'Freight_tkm');

show(GEN_CA,{'%s','%-12.0f','%-12.0f','%-12.0f','%-12.0f','%d','%d','%s','%-12.0f','%-12.0f'},...
     showfile,'\t',{...
    ['MANIFEST DATA MFA RESULTS for year ' num2str(year)],...
    ['Drawn from file ' manfile],...
                   'Weight Results in metric tons (1000 kg)',...
                   'Distance Results in km',...
    ['mdmfa version ' VERSION ' on ' date]})

show(Generation,'',showfile,'\t',{... % {'%d','%s','f','f','f'}
    WasteDesc,
    'Generation by County',
    [FN{3} ': Total reported generation by county'],
    [FN{4} ': Total of Collection_ Bulking_ and Storage for Transfer by county'],
    [FN{5} ': H141 Shortfall by county'],
    [FN{6} ': Net Generation by county']} )

show(IMPORT,{'%f','%d','%s'},showfile,'\t',{...
    ['Import of ' WasteCode ', Total']})


show(Transfer,'',showfile,'\t',{...
    WasteDesc,...
    'Transfer Stations by total shipments received',...
    ['(Cutoff is ' num2str(cutoff) ' t)']})

show(trunc(Destinations,3,10,'ddaa'),'',showfile,'\t',{...
    WasteDesc, ' Disposed In State by TSDF Facility'})

show(Fates,'',showfile,'\t',{...
    WasteDesc, ' Disposed In State by Disposal Method'})

show(trunc(ExDest_State,3,10,'ddaa'),'',showfile,'\t',{...
    WasteDesc, ' Exported by Destination State'})

show(trunc(ExDest_TSDF,3,10,'ddaa'),'',showfile,'\t',{...
    WasteDesc, ' Exported by TSDF Facility'})

show(ExFates,'',showfile,'\t',{...
    WasteDesc, ' Exported by Disposal Method'})

show(Freight,{'%-8.f','%-8.d','%-8.f','%-12.f'},showfile,'\t',{...
    'Freight Transport Estimate over all loads beginning and ending in CA',...
    'Straight-line Distance between county centroids'...
    ['Mean distance per load: ' num2str(Freight.Freight_tkm/Freight.Accum__TONS), ...
     ' km']})

R = GEN_CA; % assign results
R.Outputs_CA=Outputs_CA;
R.Outputs_Ex=Outputs_Ex;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fn=check_file(fn)
if ~exist(fn,'file')
  fn=input(['Cannot find file ' fn '; enter path/file: '],'s');
end
