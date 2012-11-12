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
                        {'s','n','n','s','s','','s','s','s','s','s','','s',''}, ...
                        struct('Field',{'FAC_NAME'},'Test',{@isempty}, ...
                               'Pattern',{''},'Inv',{1}));
  % Facilities = 
  %     GEN_EPA_ID
  %     NAICS_COUNT
  %     SIC_COUNT
  %     FAC_NAME
  %     FAC_STR1
  %     FAC_CITY
  %     FAC_CNTY
  %     FAC_ST
  %     FAC_ZIP
  %     FAC_ACT_IND
  %     CREATE_DATE
  %     NAICS_CODE
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
      
        if WCs(j)==223
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

      if WCs(j)~=223
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
      MD.(manname)=meth_correct(MD.(manname));
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

if GEN_NODE | GEN_NODE_FORCE
  fprintf('%s ... %.1f sec\n','Computing Node Mass Balances',toc)
  for i=1:length(YEARS)
    yy=num2str(YEARS(i));
    for j=1:length(WCs)
      wc=num2str(WCs(j));

      tanner_suffix=['_' yy '_' wc];

      manname=['Q' tanner_suffix];
      nodename=['Rn' tanner_suffix];

      if exist('Node','var') & isfield(Node,nodename) & ~GEN_NODE_FORCE
        fprintf('%s exists: nothing to do.\n',nodename)
      else
        fprintf('Computing node balance: %s\n',nodename)
        Rn=uo_node(MD.(manname),TANNER_TERMINAL,TANNER_DISP,TANNER_CUTOFF);
        [Rn(1:end).Year]=deal(YEARS(i));
        [Rn(1:end).WASTE_STATE_CODE]=deal(wc);
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

if LOAD_CR_PROC
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
    
    if isfield(Node,crname)
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
        [An(1:end).WASTE_STATE_CODE]=deal(wc);
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