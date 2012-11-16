function D=uo_load(dbase,prefix,year,wc)
% function D=uo_load(dbase,prefix,year,arg)
%
% Stores all the idiosyncratic information necessary to read in primary data.
% Also functions as a clearing house for performing data corrections.  Current
% corrections performed are described by-database.
% 
% dbase should be one of:
%  'MD' - use manifest data.  Base directory is '../HWTS/TannerYYYY' where YYYY =
%         year.  If ARG is 223, loads the special MD_units_YYYY_WWW file.
%   
%         MD corrections include:
%         - applying uniform field names to manifest structures
%         - mapping outdated and erroneous method codes to proper codes
%         - correcting erroneous container codes (MD-223 only)
%         - filling in blank EPAIDs with SOURCE_UNKNOWN and DESTINATION_UNKNOWN


switch dbase
  case 'MD'
    % reading manifest data
    % now: we read in the manifest data.  filter on waste code
    
    % manifest_read assumes wastecode is a string, not a number.  regexp is quicker
    % than str2double.
    if isnumeric(wc) wc=num2str(floor(wc)); end
    tanner_suffix=[ '_' num2str(year) '_' wc];
    savefile=['UO_MD' tanner_suffix];
    savevars={['Q' tanner_suffix]};

    if exist([savefile '.mat'],'file')
      D=load(savefile);
    else
      % need to generate the data
      unit_srcfile=[prefix '/Tanner' num2str(year) '/MD_units' tanner_suffix ...
                    '.csv'];
      if exist(unit_srcfile,'file')
        
        MD=read_dat(unit_srcfile,',',{'s','s','s','s','s','n','s'}); % no filter- all 223
        MD=container_correct(MD);
        disp('Adding county data to 223 manifest record..')
        MD=mvfield(flookup(MD,'GEN_EPA_ID','FAC_CNTY'),'FAC_CNTY','GEN_CNTY', ...
                   'bla');
        MD=mvfield(flookup(MD,'TSDF_EPA_ID','FAC_CNTY'),'FAC_CNTY','TSDF_CNTY', ...
                   'bla');
        MD=orderfields(MD,[1 8 2 9 3:7]);
        
      else
        manfiles={'TANNER2011.txt',%2011
                  'Manifest.txt',%2010
                  'MANIFEST.txt',%2009
                  'tanner2008.txt',
                  'TANNER2007.txt',
                  'TANNER2006.txt',
                  'tanner2005.txt',
                  'tanner2004.txt',
                  'tanner2003.txt',
                  'tanner2002.txt',
                  '2001_SUMMARY.txt',
                  'tanner2000.txt',
                  'tanner_1999.txt',
                  'tanner_1998.txt',
                  'tanner_1997.txt',
                  'tanner_1996.txt',
                  'tanner_1995.txt',
                  'tanner_1994.txt',
                  'tanner_1993.txt'         };
        srcfile=[prefix '/Tanner' num2str(year) '/' manfiles{2012-year}];
        
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
            manifest_read={'s','n','s','n','s','s','n'};
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
        
        
        
        MD=read_dat(srcfile,',',manifest_read,...
                    struct('Field',WASTE_STATE_CODE,'Test',{@regexp},'Pattern', ...
                             wc));
        MD=MD(:);
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
          
      end
      if year<2007
        MD=meth_correct(MD,1);
      else
        MD=meth_correct(MD);
      end
      MD=blank_epaid_correct(MD);
      
      %keyboard
      D.(savevars{1})=MD;
      save(savefile,'-struct','D',savevars{:});
    end % if exist([savefile '.mat'],'file') / else

  case 'CR'
    % CalRecycle database-- only interested in processor data; read from scratch
    % include all years
    savevars={'CR_Proc','CR_Hauler','CR_Sales','CR_Txfr'};
    src_file{1}=[prefix '/CR-processor.csv'];
    src_file{2}=[prefix '/CR-hauler.csv'];
    src_file{3}=[prefix '/CR-sales.csv'];
    src_file{4}=[prefix '/CR-transfer.csv'];
    
    CR=read_dat(src_file{1},',',{'','','n','s','s','','','','','',...
                      'n','n','n','n','n','n','n','n','n','s','s',... % through StateCountry
                      'n','n','n','n','n','n', ... % through Recycled
                      'n','n','','','n', ... % Residual
                      'n','n','n','n'});
    CR=crquarteryear(CR);
    
    D.(savevars{1})=CR;
    D.(savevars{2})=crquarteryear(read_dat(src_file{2},',',...
                                           {'','','n','s','s','','','','','','n'}));

    D.(savevars{3})=read_dat(src_file{3},',','n');
    D.(savevars{4})=crtxfrcorr(src_file{4});
    

  case 'RCRA'
    src_file=[prefix '/RCRA-W206-BR-2003-2009.csv'];
    
    RCRA=read_dat(src_file,',',{'n','s','s','s','','','s','s','n','s','s','s','s','s','s'});

    for i=1:length(year)
      D.(['RCRA_' num2str(year(i))])=filter(RCRA,'Year',{@eq},year(i));
    end
    
  otherwise
    error(['Unknown database prefix ' dbase])
end
%  disp(['Loading manifest data from ' mdfile])
    %  load(mdfile)
    %  eval(['MD=' mdfile ';']);
    %end
    %clear(mdfile) % MD is our content
%% disp('Deblanking waste code') %% done 
%% MD=moddata(MD,'WASTE_STATE_CODE',@(x)(num2str(str2num(x))))

function Q=blank_epaid_correct(Q,BLANK_GEN,BLANK_DEST)
% fills in blank GEN_EPA_ID and blank TSDF_EPA_ID with the supplied values or
% sensible defaults: CA0000000000 (for SOURCE UNKNOWN) or CA9999999999 (for
% DESTINATION UNKNOWN)

[~,M]=filter(Q,'GEN_EPA_ID',{@isempty},'');
if sum(M)>0
  [Q(M).GEN_EPA_ID]=deal('CA0000000000');
end
[~,M]=filter(Q,'TSDF_EPA_ID',{@isempty},'');
if sum(M)>0
  [Q(M).TSDF_EPA_ID]=deal('CA9999999999');
end

function [D,DID]=crquarteryear(D,fn)
% function D=crquarteryear(D)
% converts CalRecycle quarter-year ID field to Quarter and Year.  Replaces the one
% field with two (second field inserted in-place).
%
% function D=crquarteryear(D,fn)
% By default, uses fieldname 'QuarterYearID', but an alternative fieldname can be
% provided as an optional second argument.
%
% mapping from QuarterYearID to quarter: mod(*-3,4)={0,1,2,3} -> {Q1,Q2,Q3,Q4}
% mapping from QuarterYearID to year: 1874+floor((*-3)/4) = year
%
% Example: QuarterYearID=550 corresponds to Oct-Dec 2010
%

if nargin<2
  fn='QuarterYearID';
end

FN=fieldnames(D);

I=find(strcmp(FN,fn));
switch(fn)
  case 'QuarterYearID'
    D=moddata(D,fn,@(x)(1874+floor((x-3)/4)),'Year');
    D=moddata(D,fn,@(x)(['Q' num2str(1+mod(x-3,4))])); % replace field
  case 'QuarterYear'
    QYMap=struct('Str',{'Ja','Ap','Ju','Oc'},'Map',{'Q1','Q2','Q3','Q4'});
    D=moddata(D,'QuarterYear',@(x)(cell2mat(regexp(x,'[0-9]{4}','match'))),'Year');
    D=vlookup(moddata(D,fn,@(x)(subsref(x,substruct('()',{1:2})))),...
              fn,QYMap,'Str','Map','inplace');
  otherwise
    disp(['fn = ' fn '; I''m confused.'])
    keyboard
end
D=orderfields(D,[1:I, length(FN)+1, (I+1):length(FN)]);
D=mvfield(D,fn,'Quarter');

if nargout>1
  DID=accum(D,'ddmm'); % accum list of EPAIDs
  DID=orderfields(DID,[2 3 1]);
  DID=flookup(DID,'EPAIDNumber','FAC_NAME'); % crosscheck them against
                                             % facility master list
end

function CR_Txfr=crtxfrcorr(fname)

  CR_Txfr=read_dat(fname,',',{'s','s','s','s','s','s','s','n','n','n'});
  CR_Txfr=crquarteryear(CR_Txfr,'QuarterYear');
  
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
  
  CR_Txfr=moddata(CR_Txfr,'DestType',@(x)(regexprep(x,'Re-refiner',...
                                                    're-refiner')));
  % take first char and concatenate; Recycler distinct from re-refiner
  CR_Txfr=moddata(CR_Txfr,'DestType',@(x)(subsref(x,substruct('()',{1}))));
  CR_Txfr=accum(CR_Txfr,'ddmdcmmmmmm'); % m instead of a to screen double
                                              % entries 
  CR_Txfr=moddata(CR_Txfr,'Year',@str2num);
  
