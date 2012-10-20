% Script file to read in and preprocess CalRecycle data.

global GEO_CONTEXT
global use_md2
if ~strcmp(GEO_CONTEXT,'Facilities')
  warning('Geographic context should be ''Facilities''')
end

do_readdata=false;
use_md2=true;

savefile='CRData.mat';
do_save=false;
do_correction=false;

do_computation=true;
do_MD=false;
force_MD=false;
do_csv=false;
years=2011;
wc=221:223;


if do_csv
  printcsv={'printcsv'};
else
  printcsv={};
end
if force_MD
  forceMD={'force'};
else
  forceMD={};
end

if do_readdata
  %% Part 0- Sales Data
  fprintf('%s\n','WARNING- data needs for CR-sales.csv: ',' * put in quarter-year data',...
                  ' * add in motor-carrier and commerce exemption data')
  CRData.Sales=read_dat('CR-sales.csv',',','d');
  %% these are in million gallons
  
  %% ------------------------------------------------------------------------
  %% Part 1- Hauler Data
  disp('Part 1 - Hauler Data')
  CRData.Hauler=read_dat('CR-hauler.csv',',',{'','','n','s','s','','','','','','n'});
  [CRData.Hauler,CRData.H_ID]=crquarteryear(CRData.Hauler);
  % Quarter,
  % Year,
  % FacilityName,
  % EPAIDNumber,
  % LubCollectionStationsGallons,
  % LubIndustrialGallons,
  % LubMarineGallons,
  % LubAgriculturalGallons,
  % LubGovernmentGallons,
  % LubOutOfStateGallons,
  % LubOtherHaulersGallons,
  % LubTotalGallons,
  % IndCollectionStationsGallons,
  % IndIndustrialGallons,
  % IndMarineGallons,
  % IndAgriculturalGallons,
  % IndGovernmentGallons,
  % IndOutOfStateGallons,
  % IndOtherHaulersGallons,
  % IndTotalGallons,
  % GrandTotalGallons,
  % TotalLubTransferedGallons,
  % TotalIndTransferedGallons,
  % TotalTransferedGallons
  
  
  
  
  
  %% ------------------------------------------------------------------------
  %% Part 2- Processor Data
  disp('Part 2 - Processor Data')
  CRData.Proc=read_dat('CR-processor.csv',',',{'','','n','s','s','','','','','',...
                      'n','n','n','n','n','n','n','n','n','s','s',... % through StateCountry
                      'n','n','n','n','n','n', ... % through Recycled
                      'n','n','','','n', ... % Residual
                      'n','n','n','n'});
  [CRData.Proc,CRData.P_ID]=crquarteryear(CRData.Proc);
  % Quarter,
  % Year,
  % FacilityName,
  % EPAIDNumber,
  % LubOilInCAGallons,
  % IndOilInCAGallons,
  % TotalOilInCAGallons,
  % LubOilOutsideCAGallons,
  % IndOilOutsideCAGallons,
  % TotalOilOutsideCAGallons,
  % TotalLubGallons,
  % TotalIndGallons,
  % GrandTotalOilReceivedGallons,
  % LubOilStateCountry,
  % IndOilStateCountry,
  % RecycledOilNeutralBaseStockGallons,
  % RecycledOilIndustrialOilGallons,
  % RecycledOilFuelOilGallons,
  % RecycledOilAsphaltGallons,
  % RecycledOilConsumedGallons,
  % RecycledOilTotalGallons,
  % ResidualMaterialNonhazardousGallons,
  % ResidualMaterialHazardousGallons,
  % ResidualMaterialTotalGallons,
  % ProducedByFacilityGrandTotalGallons,
  % TotalLubTransferedGallons,
  % TotalIndTransferedGallons,
  % TotalTransferedGallons
  
  
  
  %% ------------------------------------------------------------------------
  %% Part 3- Recycler Data
  disp('Part 3 - Recycler Data')
  CRData.Rec=read_dat('CR-recycler.csv',',',{'s','s','s','n','n','n','n','n','n'});
  CRData.Rec=crquarteryear(CRData.Rec,'QuarterYear');
  % FacilityName,
  % EPAID,
  % Quarter,
  % Year,
  % LubeOilCA,
  % IndOilCA,
  % LubeOilNonCA,
  % IndOilNonCA,
  % LubeOilTransfered,
  % IndOilTransfered
  
  CRData.R_ID=orderfields(accum(CRData.Rec,'mm'),[2 3 1]);
  CRData.R_ID=flookup(CRData.R_ID,'EPAID','FAC_NAME');
  
  
  %% ------------------------------------------------------------------------
  %% Part 4- Refund Data
  disp('Part 4 - Refund Data')
  CRData.Ref=read_dat('CR-refund.csv',',',{'','s','n','n','n','n','n','n','n'});
  CRData.Ref=crquarteryear(CRData.Ref,'QuarterYear');
  % RefundClaim,
  % QuarterYear,
  % ExportGal,
  % InterstateGal,
  % MotorCarrierGal,
  % PurchasedFromCAGal,
  % FedGovGal,
  % TotalOilGal,
  % TotalAmount
  CRData.Ref=sort(accum(CRData.Ref,'mmaaaaaaa'),2,'ascend');
  
  
  %% ------------------------------------------------------------------------
  %% Part 5- Transfer Data
  disp('Part 5 - Transfer Data')
  CRData.Txfr=read_dat('CR-transfer.csv',',',{'s','s','s','s','s','s','s','n','n','n'});
  CRData.Txfr=crquarteryear(CRData.Txfr,'QuarterYear');
  
  % SourceName,
  % RptSrc,
  % SrcEPAID,
  % DestinationName,
  % DestType,
  % DestEPAID,
  % Quarter,
  % Year,
  % LubeOil,
  % IndOil,
  % Total
  
  %%% don't really know what to do with this, since the double counting at first
  % seems inscrutable. I think there is something going on where every entry with a
  % "Transfer Station" destination is double counted, but I can't be sure.
  
  % for 2010 (746 records):
  % 63 distinct destination facilities
  % 83 distinct destination-type pairs (i.e. 20 double entries)
  % 102 distinct source facilities
  % 103 distinct source-type pairs (i.e. 1 double entry)
  
  % assertion: Two records are duplicate if they share SrcEPAID, DestEPAID, Quarter,
  % Year, LubeOil, IndOil, Total AND have different DestTypes.  A function to screen
  % out duplicates will have to step through each record in sequence, checking it
  % against all subsequent entries (and skipping those already marked as duplicates).
  
  disp('Performing double counting hunt')
  
  CRData.Txfr_DC=moddata(CRData.Txfr,'DestType',@(x)(regexprep(x,'Re-refiner',...
                                                    're-refiner')));
  CRData.Txfr_DC=moddata(CRData.Txfr_DC,'DestType',@(x)(subsref(x,substruct('()',{1}))));
  CRData.Txfr_DC=accum(CRData.Txfr_DC,'ddmdcmmmmmm');
  CRData.Txfr_DC=moddata(CRData.Txfr_DC,'Year',@str2num);
  
else
  load CRData;
end

%% ----------------------------------------
%% Make adjustments to flows to curate data



% Tc


%% Txfr_Corr is a list of SrcEPAID and DestEPAID-- for each SrcEPAID, accumulate total
%inbound minus total outbound in the manifest list so far; create a new manifest
%transferring the balance from Src to Dest.  Use METH_CODE Y039, corrective
%transfer.

if do_correction
  fprintf('%s','Reading Transfer auto-corrections: ')
  CRData.Txfr_Corr=read_dat('TxfrCorr.csv',',');
  CRData.Do_Txfr_Corr=true;
else
  fprintf('%s\n','Disabling Transfer auto-correction')
  CRData.Do_Txfr_Corr=false;
end

%% =================================================================
%% Crunch!

if do_save
  disp(['Saving data files to ' savefile])
  save(savefile, 'CRData')
else
  disp(['Not saving.'])
end


if do_computation
  for i=1:length(years)
    if do_MD
      for j=1:length(wc)
        if use_md2
          disp(['Running md_node2 for ' num2str(years(i)) ', WC ' num2str(wc(j))]);
          md_node2(years(i),wc(j),printcsv{:},forceMD{:});
        else
          disp(['Running md_node for ' num2str(years(i)) ', WC ' num2str(wc(j))]);
          md_node(years(i),wc(j),printcsv{:},forceMD{:});
        end
      end
    end
    disp(['Running cr_node for ' num2str(years(i))]);
    cr_node(CRData,years(i),printcsv{:});
  end
end


