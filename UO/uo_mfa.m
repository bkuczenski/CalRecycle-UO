%% script file for performing the UO mfa
%%


%% Load configuration
uo_config


NODE_PIVOT_FILE=[NODE_PIVOT_PREFIX '_' num2str(YEARS(1))];
ACTIVITY_FILE=[ACTIVITY_FILE_PREFIX '_' num2str(YEARS(1))];
if length(YEARS)>1
  ACTIVITY_FILE=[ACTIVITY_FILE '_' num2str(YEARS(end))];
  NODE_PIVOT_FILE=[NODE_PIVOT_FILE '_' num2str(YEARS(end))];
end
NODE_PIVOT_FILE=[NODE_PIVOT_FILE '.xls'];
ACTIVITY_FILE=[ACTIVITY_FILE '.xls'];



tic
fprintf('USED OIL MFA -- Start to finish\n')
fprintf('Output Variables:\n')
fprintf('  %6s - %s \n','MD','Manifest Data',...
        'Node','Facility Mass balance and activity')

GAL_PER_TON='2000/7.5';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Generate Facilities Database
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if READ_FACILITIES | ~exist('FacilitiesUO.mat','file')
  fprintf(1,'Reading facilities database: %.1f sec \n',toc)
  global Facilities FACILITIES GEO_CONTEXT GEO_REGION UNIT_CONV
  Facilities = read_dat([FACILITIES_PREFIX FACILITIES_FILE],',', ...
                        {'s','','','s','s','','s','s','s','s','s','','s',''}, ...
                        struct('Field',{'FAC_NAME'},'Test',{@isempty}, ...
                               'Pattern',{''},'Inv',{1}));
  % Facilities = 
  %     GEN_EPA_ID
  %X     NAICS_COUNT
  %X     SIC_COUNT
  %     FAC_NAME
  %     FAC_STR1
  %     FAC_CITY
  %     FAC_CNTY
  %     FAC_ST
  %     FAC_ZIP
  %     FAC_ACT_IND
  %     CREATE_DATE
  [FACILITIES,ind]=sort({Facilities(:).GEN_EPA_ID});
  Facilities=Facilities(ind);

  fprintf(1,'Saving Facilities data in %s.mat\n.','FacilitiesUO')
  GEO_CONTEXT='Facilities_UO'
  GEO_REGION='^CA'

  % compute unit conversion G / K / L / M / N / P / T / Y
  UNITS={'G','K','L','M','N','P','T','Y'};
  UNIT_CONV=cell2struct(...
      { 'G', 1, 3.402, 3.785, .003402, .003785, 7.5, .00375, .004951 },...
      { 'UNIT',UNITS{:}},2);
  
  for k=2:length(UNITS)
    UNIT_CONV(k).UNIT=UNITS{k};
    for j=1:length(UNITS)
      UNIT_CONV(k).(UNITS{j}) = UNIT_CONV(1).(UNITS{j}) / UNIT_CONV(1).(UNITS{k});
    end
  end

  save FacilitiesUO FACILITIES Facilities GEO_CONTEXT GEO_REGION UNIT_CONV
else
  if ~exist('GEO_CONTEXT','var')
    fprintf('Loading geographic context')
    load_geo
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Apply NAICS codes to Facilities Database
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if READ_NAICS | ~isfield(Facilities,'NAICS_CODE')
  %     NAICS_CODE
  fprintf(1,'Adding NAICS codes to Facilities (this is SLOW): %.1f sec\n',toc)
  fprintf(1,'Reading NAICS database:\n')
  FN=read_dat([FACILITIES_PREFIX NAICS_FILE],',',{'s','s','',''},...
              struct('Field',{'NAICS_CODE'},'Test',{@isempty}, ...
                    'Pattern',{''},'Inv',{1}));
  FN=sort(FN,'GEN_EPA_ID');
  clear FacNAICS
  fprintf(1,'Collapsing and removing duplicates:\n')
  while length(FN)~=0
    k=min([length(FN),2000]);
    while k < length(FN) & strcmp(FN(k).GEN_EPA_ID,FN(k+1).GEN_EPA_ID)
      k=k+1;
    end
    if exist('FacNAICS')
      FNC=accum(FN(1:k),'mm');
      FacNAICS=[FacNAICS ; accum(FNC,'mc',{'a','',' '})];
    else
      FNC=accum(FN(1:k),'mm');
      FacNAICS=accum(FNC,'mc',{'a','',' '});
    end
    FN=FN(k+1:end);
  end
  fprintf(1,'appending to facilities database:\n')
  [Facilities,Mf]=vlookup(Facilities,'GEN_EPA_ID',FacNAICS,'GEN_EPA_ID','NAICS_CODE','bla', ... 
          'exact');
  [Facilities(~Mf).NAICS_CODE]=deal('');
  Facilities=moddata(Facilities,'NAICS_CODE',@deblank);
  save FacilitiesUO FACILITIES Facilities GEO_CONTEXT GEO_REGION UNIT_CONV
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Apply Lat/Long to Facilities Database - as 2-element vector
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if READ_LAT_LONG | ~isfield(Facilities,'LAT_LONG')
  %     LAT_LONG - 2-element concatenation 
  fprintf(1,'%s ... %.1f sec\n','Adding Lat/Long to Facilities Database',toc)
  FLL=read_dat([FACILITIES_PREFIX LAT_LONG_FILE],',',{'n','','','s','s','','','n','n'},...
               struct('Field',{'ZIP5'},'Test',{@eq},'Pattern',{0},'Inv',{1}));

  if 1 % URL_LOOKUP_MISSING
    fprintf(1,'%s ... %.1f sec\n','Performing URL lookup Lat/Long for missing ZIPs',toc)
    [~,M]=filter(FLL,'POINT_X',{@eq},0);
    ZIP_missing=unique({FLL(M).ZIP5});
    err_list=[];
    for k=1:size(ZIP_missing,2)
      if mod(k,100)==1 
        disp([num2str(k-1) ' ZIPs done (' num2str(size(ZIP_missing,2)) ' total)'])
      end
      [s,st]=urlread(sprintf('http://%s/%2.2s/%05d.html','www.brainyzip.com/zipcodes',...
                             ZIP_missing{1,k},str2num(ZIP_missing{1,k})));
      if st
        Lat=regexp(s,'L[atong]+itude[^0-9-+.]+([0-9-+.]+)','tokens');
        ZIP_missing([2,3],k)=[Lat{:}];
      else
        disp(['URL read failed for ZIP ' ZIP_missing{1,k} ' (' num2str(k) ')'])
        err_list=[err_list k];
      end
    end
    ZIP_missing(:,err_list)=[];
    ZIP_missing=cell2struct(ZIP_missing,{'ZIP5','POINT_Y','POINT_X'});

    % apply lookedup results to FLL
    [FLL(M)]=vlookup(FLL(M),'ZIP5',ZIP_missing,'ZIP5','POINT_X','zer');
    [FLL(M)]=vlookup(FLL(M),'ZIP5',ZIP_missing,'ZIP5','POINT_Y','zer');
  end
  LAT_LONG=num2cell([FLL(:).POINT_Y; FLL(:).POINT_X]',2);
  [FLL.LAT_LONG]=deal(LAT_LONG{:});
  
  fprintf(1,'%s ... %.1f sec\n','Appending LAT_LONG to facilities database',toc)
  
  Facilities=vlookup(Facilities,'GEN_EPA_ID',FLL,'GEN_EPA_ID','LAT_LONG','zer');
  save FacilitiesUO FACILITIES Facilities GEO_CONTEXT GEO_REGION UNIT_CONV
end
  
%% okay, so we read in the facility data
%% (use read_fac as template to revise stored data)

%% now what?  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Generate corrected manifest records
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if LOAD_MD_NODE | ~exist('MD','var')
  if exist('MD.mat','file')
    fprintf('%s ... %.1f sec\n','Loading MD.mat',toc)
    load MD
  end
  if exist('Node.mat','file')
    fprintf('%s ... %.1f sec\n','Loading Node.mat',toc)
    load Node
  end
end

if GEN_MD
  fprintf('%s ... %.1f sec\n','Generating Manifest Tables',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      manname=['Q' tanner_suffix];

      if exist('MD','var') & isfield(MD,manname)
        fprintf('%s exists: nothing to do.\n',manname)
      else
        fprintf('Reading manifest data for %s\n',manname)
        %% Load Manifest Data from original Tanner files
        if exist('MD','var')
          MD=union(MD,uo_load('MD',TANNER_PREFIX,YEARS(i),WCs(j)));
        else
          MD=uo_load('MD',TANNER_PREFIX,YEARS(i),WCs(j));
        end
      
        if isfield(MD.(manname),'QUANTITY') % do 223 conversion
          [MD.(manname),Qx]=screen223(MD.(manname));
        else
          % get rid of NANs
          [MD.(manname)(find(isnan([MD.(manname).TONS]))).TONS]=deal(0);
          % convert to GAL
          fprintf('Converting 1 ton = %d gal\n',eval(GAL_PER_TON))
          MD.(manname)=rmfield(fieldop(MD.(manname),'GAL',...
                                       ['floor( #TONS * ' GAL_PER_TON ')']), 'TONS');
          
        end
        %% correct TSDF_EPA_IDs and store
        MD.(manname)=correct_epaid(MD.(manname),'TSDF_EPA_ID',true);
        save MD MD
        if exist('Node','var')
          % if we change MD, we need to strike all the derived nodes
          FN=fieldnames(Node);
          % need to re-gen all Activity tables
          Node=rmfield(Node,FN(~cellfun(@isempty,strfind(fieldnames(Node), ...
                                                         tanner_suffix))));
          save Node Node
        end
      end
      
    end
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Just perform unit conversions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if UNITCONV_MD
  fprintf('%s ... %.1f sec\n','Performing unit conversions',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      manname=['Q' tanner_suffix];

      if WCs(j)~=223 & isfield(MD.(manname),'TONS')
        % get rid of NANs
        [MD.(manname)(find(isnan([MD.(manname).TONS]))).TONS]=deal(0);
        % convert to GAL
        fprintf('Converting 1 ton = %d gal\n',eval(GAL_PER_TON))
        MD.(manname)=rmfield(fieldop(MD.(manname),'GAL',...
                                     ['floor( #TONS * ' GAL_PER_TON ')']), 'TONS');
        
        if exist('Node','var')
          % if we change MD, we need to strike all the derived nodes
          FN=fieldnames(Node);
          % need to re-gen all Activity tables
          Node=rmfield(Node,FN(~cellfun(@isempty,strfind(fieldnames(Node), ...
                                                         tanner_suffix)))); 
        end
      end
    end
  end
  save MD MD
  if exist('Node','var')
    save Node Node
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Re-apply method code corrections
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if RE_CORR_METH
  fprintf('%s ... %.1f sec\n','Applying meth_code corrections',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      manname=['Q' tanner_suffix];
      if YEARS(i)<2007
        MD.(manname)=meth_correct(MD.(manname),1);
      else
        MD.(manname)=meth_correct(MD.(manname));
      end
      if exist('Node','var')
        % if we change MD, we need to strike all the derived nodes
        FN=fieldnames(Node);
        % need to re-gen all Activity tables
        Node=rmfield(Node,FN(~cellfun(@isempty,strfind(fieldnames(Node),...
                                                       tanner_suffix))));
      end
    end
  end
  save MD MD
  if exist('Node','var')
    save Node Node
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Generate node data
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if GEN_NODE | FORCE_GEN_NODE
  fprintf('%s ... %.1f sec\n','Computing Node Mass Balances',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      manname=['Q' tanner_suffix];
      nodename=['Rn' tanner_suffix];

      if exist('Node','var') & isfield(Node,nodename) & ~FORCE_GEN_NODE
        fprintf('%s exists: nothing to do.\n',nodename)
      else
        fprintf('Computing node balance: %s\n',nodename)
        Rn=uo_node(MD.(manname),TANNER_TERMINAL,TANNER_DISP,TANNER_CUTOFF);
        [Rn(1:end).Year]=deal(YEARS(i));
        [Rn(1:end).WC]=deal(wc);
        nf=length(fieldnames(Rn));
        Node.(nodename)=orderfields(Rn,[1 nf nf-1 2:nf-2]);
      end
    end
  end
  save Node Node
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Append CalRecycle Data
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if FORCE_CR_PROC & isfield(Node,'CR_Proc') 
  Node=rmfield(Node,'CR_Proc');
end

if LOAD_CR_PROC | FORCE_CR_PROC
  fprintf('%s ... %.1f sec\n','Appending CalRecycle processor data',toc);

  if ~isfield(Node,'CR_Proc') 
    Node=union(Node,uo_load('CR',CALRECYCLE_PREFIX));
  end
  for i=1:length(YEARS)

    yy=num2str(YEARS(i));
    nodename=['Rn_' yy '_221'];
    crname=['CR_' yy];

    % cleanup
    if isfield(Node.(nodename),'CR_inGAL')
      Node.(nodename)=rmfield(Node.(nodename),{'CR_inGAL','CR_prodGAL', ...
                          'CR_resGAL'});
      Node=rmfield(Node,crname); % reload to get ind fraction
    end
    
    if isfield(Node,crname) & ~FORCE_CR_PROC
      fprintf('%s exists: nothing to do.\n',crname)
      CRa=Node.(crname);
    else
      fprintf('Computing CR totals: %s\n',crname)
      CRa=select(accum(filter(Node.CR_Proc,'Year',{@eq},YEARS(i)),'dmdm',''),...
                 {'Year','EPAIDNumber','GrandTotalOilReceivedGallons', ...
                  'RecycledOilTotalGallons','ResidualMaterialTotalGallons',...
                  'TotalIndGallons'});
      % transfers column just makes NO consistent sense
      CRa=mvfield(CRa,'EPAIDNumber','CR_EPA_ID');
      CRa=mvfield(CRa,'GrandTotalOilReceivedGallons','CR_GAL');
      CRa=mvfield(CRa,'RecycledOilTotalGallons','CR_prodGAL');
      CRa=mvfield(CRa,'ResidualMaterialTotalGallons','CR_residGAL');
      CRa=mvfield(CRa,'TotalIndGallons','CR_indGAL');
      Node.(crname)=CRa;
    end
    fprintf('Appending to %s \n',nodename)
    if isfield(Node.(nodename),'CR_GAL')
      Node.(nodename)=rmfield(Node.(nodename),{'CR_GAL','CR_prodGAL','CR_residGAL','CR_indGAL'});
    end
      
    FN=fieldnames(Node.(nodename));
    Node.(nodename)=vlookup(Node.(nodename),'TSDF_EPA_ID',CRa,'CR_EPA_ID','CR_GAL', ...
                          'zer');
    Node.(nodename)=vlookup(Node.(nodename),'TSDF_EPA_ID',CRa,'CR_EPA_ID','CR_prodGAL', ...
                          'zer');
    Node.(nodename)=vlookup(Node.(nodename),'TSDF_EPA_ID',CRa,'CR_EPA_ID','CR_residGAL', ...
                          'zer');
    Node.(nodename)=vlookup(Node.(nodename),'TSDF_EPA_ID',CRa,'CR_EPA_ID','CR_indGAL', ...
                          'zer');
    
    Node.(nodename)=select(Node.(nodename),{FN{1:11},...
                        'CR_GAL','CR_indGAL','CR_prodGAL','CR_residGAL',...
                        FN{12:end}});
    %[1:11 nf-2 nf nf-1 12:nf-3]);
  end
  save Node Node
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Append RCRA Data
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
if GEN_RCRA
  if ~isfield(MD,['RCRA_' num2str(RCRA_YEARS(1))])
    fprintf('%s ... %.1f sec\n','Reading RCRA data',toc)
    MD=union(MD,uo_load('RCRA','../RCRAData',RCRA_YEARS));
  end

  for i=1:length(RCRA_YEARS)
    fprintf('%s ... %.1f sec\n','Computing RCRA node balances',toc)
    rcraname=['RCRA_' num2str(RCRA_YEARS(i))];
    manname=['RCRA_Q_' num2str(RCRA_YEARS(i))];
    nodename=['RCRA_Rn_' num2str(RCRA_YEARS(i))];
    nodetgt=['Rn_' num2str(RCRA_YEARS(i)) '_221'];
    MD.(manname)=select(MD.(rcraname),{'GEN_EPA_ID','GEN_NAME','TSDF_EPA_ID','TSDF_NAME',...
                        'FormCode','METH_CODE','TONS','HazWasteCodes','HazWasteGroup'});
    MD.(manname)=rmfield(fieldop(MD.(manname),'GAL',...
                                 ['floor( #TONS * ' GAL_PER_TON ')']), 'TONS');
    MD.(manname)=orderfields(MD.(manname),[1 2 3 4 5 6 9 7 8]);
    Node.(nodename)=uo_node(filter(MD.(manname),'GEN_EPA_ID',{@regexp},'^CA'), ...
                            TANNER_TERMINAL,'H800'); 
    Node.(nodetgt)=vlookup(Node.(nodetgt),'TSDF_EPA_ID',...
                           mvfield(Node.(nodename),'DGAL','RCRA_DGAL'),...
                           'TSDF_EPA_ID','RCRA_DGAL','zer');
    
  end

  save MD MD
  save Node Node
  error('Stop after RCRA')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Generate Facility Pivot Table Output
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear Rn

if GEN_NODE_PIVOT
  fprintf('%s ... %.1f sec\n','Generating Node Pivot Table',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      nodename=['Rn' tanner_suffix];

      if exist('Rn','var')
        Rn=stack(Rn,Node.(nodename));
      else
        Rn=Node.(nodename);
      end
    end
  end
  Rn=flookup(Rn,'TSDF_EPA_ID','FAC_NAME');
  Rn=flookup(Rn,'TSDF_EPA_ID','FAC_ST','blank');
  nf=length(fieldnames(Rn));
  Rn=orderfields(Rn,[1 nf nf-1 2:nf-2]);
  xlspivot(NODE_PIVOT_FILE,Rn);
  fprintf('%s %s ... %.1f sec\n','Open and initialize pivot table',NODE_PIVOT_FILE,toc)
  pause
  if PUBLISH_DATA  
    fprintf('%s %s\n','Publishing pivot table to',FILE_EXCHANGE)
    copyfile(NODE_PIVOT_FILE,FILE_EXCHANGE)
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Compute Activity levels on a facility-specific basis
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if APPLY_FAC_DATA
  if ~isfield(Node,'FacData') | FORCE_FAC_DATA
    fprintf('%s ... %.1f sec\n','Reading Facility Method-to-Activity spreadsheet',toc)
    
    Fac=xls2struct([FILE_EXCHANGE FAC_DATA_FILE],FAC_DATA_SHEET,{'n','s','s','s','s','n','s'});
    [Fac(isnan([Fac.FRACTION])).FRACTION]=deal(1);
    Node.FacData=Fac;
    FN=fieldnames(Node);
    % need to re-gen all Activity tables
    Node=rmfield(Node,FN(~cellfun(@isempty,strfind(fieldnames(Node),'An')))); 
    save Node Node
  end

  fprintf('%s ... %.1f sec\n','Performing Method-to-Activity conversion',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));
      
      tanner_suffix=['_' yy '_' wc];
      
      nodename=['Rn' tanner_suffix];
      actname=['An' tanner_suffix];
      
      FacWaste=filter(Node.FacData,'WASTE_CODE',{@rexegp},wc);

      if isfield(Node,actname)
        fprintf('%s exists: nothing to do.\n',actname)
      else
        fprintf('Computing %s\n',actname)
        % compute activity levels
        An=uo_activity(Node.(nodename),METH_REGEXP,FacWaste); 
        [An(1:end).Year]=deal(YEARS(i));
        [An(1:end).WC]=deal(wc);
        nf=length(fieldnames(An));
        Node.(actname)=orderfields(An,[1 nf nf-1 2:nf-2]);
      end
    end
  end
  save Node Node
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Compute Aggregate Activity levels for LCA output
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if COMPUTE_ACTIVITY
  fprintf('%s ... %.1f sec\n','Writing Activity Levels to spreadsheet',toc)
  % for now, use the same outputs as we used for stakeholder spreadsheet
  % doco

  Fates=repmat(unique({Node.FacData.FATE}),2,1);
  Fates=Fates(:)';
  Meta=struct('Date',datestr(now),...
              'Units','Gallons, as-reported basis (water content included)',...
              'Conv',sprintf('%.1f gal/short ton (%.3f kg/L)',eval(GAL_PER_TON),907.2/3.785/eval(GAL_PER_TON)),...
              'ActivityColumms','',...
              Fates{:},...
              'FacilityColumns','',...
              'WC',['California Waste Code: 221 = used oil; 222 = oil/water sludge; '...
                    '223 = other oil-containing waste'],...
              'GGAL','Apparent Generation or consolidation by the facility',...
              'ImGAL','Inflows to the facility from out of state',...
              'IgGAL','Inflows to the facility from generators in CA (first hop)',...
              'ItGAL','Inflows to the facility from transfer stations in CA (later hop)',...
              'OGAL','Outflows from the facility to CA facilities',...
              'OxGAL','Outflows from the facility to out-of-state facilities',...
              'DGAL','Apparent disposition at the facility',...
              'H039GAL','Estimated processing / recycling by the facility',...
              'HxxxGAL','Reported disposition method code (except H039)');

  xlswrite(ACTIVITY_FILE,[fieldnames(Meta) struct2cell(Meta)],'Sheet1');

  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));
      
      tanner_suffix=['_' yy '_' wc];
      actname=['An' tanner_suffix];
      
      % first, build WC tables
      if i==1
        WC{j}=accum(Node.(actname),'dmm','');
      else
        WC{j}=stack(WC{j},accum(Node.(actname),'dmm',''));
      end
      
      % then, build facility details
      if j==1
        FA{i}=Node.(actname);
      else
        FA{i}=stack(FA{i},Node.(actname));
      end
    end
    FA{i}=flookup(FA{i},'TSDF_EPA_ID','FAC_NAME');
    nf=length(fieldnames(FA{i}));
    FA{i}=orderfields(FA{i},[1 nf 2:nf-1]);
    FA{i}=sort(FA{i},'TSDF_EPA_ID');
  end
  
  for j=1:length(WCs)
    wc=num2str(WCs(j));
    fprintf(1,'%s%s\n','Writing to Excel: WC',wc)
    xlswrite(ACTIVITY_FILE,struct2xls(WC{j}),['WC' wc]);
  end

  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    fprintf(1,'%s %d %s\n','Writing to Excel: Year',YEARS(i),'detail')
    xlswrite(ACTIVITY_FILE,struct2xls(FA{i}),[yy '_Detail']);
  end

  
  fprintf('%s %s ... %.1f sec\n','Open and initialize activity sheet ',ACTIVITY_FILE,toc)
  pause
  if PUBLISH_DATA  
    fprintf('%s %s\n','Publishing activity file table to',FILE_EXCHANGE)
    copyfile(ACTIVITY_FILE,FILE_EXCHANGE)
  end
end

fprintf ('DONE \n')