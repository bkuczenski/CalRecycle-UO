function [S,maxyear]=naics(C,varargin)
% function S=naics(C)
%
% Turns NAICS codes into sector names by looking up into a table generated from
% data tables downloaded from the US Census website. or some data source.
%
% Data file currently includes full 2-6 digit NAICS codes for 2002, 2007, and
% 2012, plus a partial concordance for 1997 NAICS codes which do not match 2002
% codes. 
% 
% naics(C) where C is a char will lookup C on the database.

% naics(C,FIELD) where C is a structure with field FIELD, will perform a
% sequential lookup on the named field, returning the most recent match found in
% the field NAICS_SECTOR.
%
% naics('generate') creates NAICS.mat in the working directory from NAICS*.txt
% files assumed to be on the path.  Each file should have the fields:
%   Seq
%   NAICSyyyy
%   NAICSTitleyyyy
%
% The function starts with the most recent year, and moves to earlier years if no
% match is found.  naics(...,'-all') will display all matches; if C is a struct,
% will return columns containing all matches.
%
% [S,matchyear]=naics(C...)  where C is a char, will return the numeric value of the
% latest year with a match.
%
% [S,M]=naics(C,...) where C is a struct, will return a column vector of
% latest-matching years for each element of C.
%
% [S,M]=naics(C,...,'-all') where C is a struct, will return a structure expanded
% with NAICSTitleyyyy fields for each match and a logical matrix of matches over
% each year checked.
% 
% naics(C...,'-year') where C is a struct, will also add a column NAICS_YEAR showing
% the max year for each element of C.  No effect if C is a char- use the second
% argout. 
%
% naics(C...,'-onlyyear') where C is a struct, will add the column NAICS_YEAR
% in lieu of NAICS_SECTOR.  No effect if C is a char.
%
% naics(C...,'-correct97') will map outdated 1997 NAICS values to 2002 NAICS.
%
% currently only supports single codes-- all codes except the first are truncated.


NAICS_YEARS=[1 2012 2007 2002];
NAICS97ind=length(NAICS_YEARS)+1;
SHOWALL=false;
SHOWYEAR=0;
CORRECT97=false;

if strcmp(C,'generate')
  global NAICS
  for i=1:length(NAICS_YEARS)
    yy=num2str(NAICS_YEARS(i))
    NAICS{i}=read_dat(['NAICS_Files/NAICS' yy '.txt'],'\t',{'s','s'});
  end
  NAICS{NAICS97ind}=read_dat('NAICS_Files/NAICS97_02.txt','\t',{'s','s','s','s','s'}); % concordance

  save NAICS NAICS NAICS_YEARS
  S=true;
  return
end

if ~exist('NAICS','var')
  load NAICS
end

i=1; % start at NAICS_YEARS(1)
while length(varargin)>0
  arg=varargin{end};
  if isnumeric(arg)
    % override builtin
    i=find(arg==NAICS_YEARS);
    varargin=varargin(1:end-1);
  elseif ischar(arg) & strcmp(arg,'-all')
    SHOWALL=true;
    varargin=varargin(1:end-1);
  elseif ischar(arg) & strcmp(arg,'-year')
    SHOWYEAR=1;
    varargin=varargin(1:end-1);
  elseif ischar(arg) & strcmp(arg,'-onlyyear')
    SHOWYEAR=2;
    varargin=varargin(1:end-1);
  elseif ischar(arg) & strcmp(arg,'-correct97')
    CORRECT97=true;
    varargin=varargin(1:end-1);
  else
    % not a number or an arg- bail out of arg processing
    break
  end
end

    

if ischar(C)
  if CORRECT97
    if length(C)<6
      C=[C repmat('0',1,6-length(C))];
    end
    R02=find(strcmp(C,{NAICS{3}.NAICS2002}));
    if isempty(R02)
      R97=find(strcmp(C,{NAICS{NAICS97ind}.NAICS1997}));
      R02=NAICS{NAICS97ind}(min(R97)).NAICS2002;
    end
    S=R02;
  else
    % basic lookup
    fmax=zeros(size(NAICS_YEARS));
    while i<=length(NAICS_YEARS)
      yy=num2str(NAICS_YEARS(i));
      R{i}=find(strcmp(C,{NAICS{i}.(['NAICS' yy])}));
      if ~isempty(R{i})
        fmax(i)=max([R{i}]); % assume greatest is most specific
      end
      
      if SHOWALL
        show(NAICS{i}(R{i}));
      else
        break
      end
      i=i+1;
    end
    maxyear=NAICS_YEARS(min(find(fmax)));
    %    keyboard
    if ~isempty(maxyear)
      S=NAICS{min(find(fmax))}(fmax(min(find(fmax)))).(['NAICSTitle' num2str(maxyear)]);
    else
      % try 1997
      if length(C)<6
        C=[C repmat('0',1,6-length(C))];
      end
      try
        S=NAICS{NAICS97ind}(max(...
            find(strcmp(C,{NAICS{NAICS97ind}.NAICS1997})))).NAICSTitle1997; 
      catch
        disp('code not found in 97-02 concordance')
        keyboard
      end
    end
  end
  
elseif isstruct(C) 
  if ~isempty(varargin)
    SRC_FIELD=varargin{1};
  else
    FN=fieldnames(C);
    SRC_FIELD=FN{find(~cellfun(@isempty,strfind(FN,'NAICS')))};
%    SRC_FIELD='NAICS_CODE';
  end
  if isfield(C,SRC_FIELD)
    % condition the field: keep only the first NAICS code listed
    C=moddata(C,SRC_FIELD,@(x)(cell2mat(regexp(x,'^[0-9]+','match'))),'new__NAICS');
    empties=cellfun(@isempty,{C.new__NAICS});
    empties=empties(:);
    [C(find(empties)).new__NAICS]=deal('');
    if CORRECT97
      % replace matching 1997 fields with 2002 fields- only for fields that don't
      % already match 2002
      [C,M]=vlookup(C,'new__NAICS',NAICS{3},'NAICS2002','NAICS2002');
      try_old= ~M & ~empties;
      [C(try_old)]=moddata(C(try_old),'new__NAICS',...
                           @(x)(subsref([x '00000'],substruct('()',{1:6}))));
      [C(try_old),Mm]=vlookup(C(try_old),'new__NAICS',...
                                        NAICS{NAICS97ind},'NAICS1997','NAICS2002');
      keyboard
      [C(try_old).(SRC_FIELD)]=deal(C(try_old).NAICS2002);
      S=rmfield(C,{'new__NAICS','NAICS2002'});
      Mf=find(try_old);
      maxyear=try_old;
      maxyear(Mf(~Mm))=0;
    end
    
    % do a vlookup
    Mm=logical(zeros(size(C)));
    Mm=Mm(:);
    while i<=length(NAICS_YEARS)
      yy=num2str(NAICS_YEARS(i));
      fprintf('%d %s\n',i,yy)
      [C,M(:,i)]=vlookup(C,'new__NAICS',NAICS{i},['NAICS' yy],['NAICSTitle' yy]);
      Mm=Mm|M(:,i);
      i=i+1;
    end
    try_old=~Mm & ~empties;
    if any(try_old)
      [C.NAICSTitle1997]=deal('');
      [C(try_old)]=moddata(C(try_old),'new__NAICS',...
                           @(x)(subsref([x '00000'],substruct('()',{1:6}))));
      fprintf('%d %s\n',i,'1997')
      
      [C(try_old),M(try_old,i)]=vlookup(C(try_old),'new__NAICS',...
                                        NAICS{NAICS97ind},'NAICS1997','NAICSTitle1997');
    end
    if SHOWALL
      maxyear=M;
    else
      [C.NAICS_SECTOR]=deal('');
      for i=1:length(NAICS_YEARS)
        titlefield=['NAICSTitle' num2str(NAICS_YEARS(i))];
        [C(M(:,i)).NAICS_SECTOR]=deal(C(M(:,i)).(titlefield));
        C=rmfield(C,titlefield);
        maxyear(M(:,i))=NAICS_YEARS(i);
        for j=i+1:size(M,2)
          M(:,j)=M(:,j) & ~M(:,i);
        end
      end
      if (sum(M(:,end)))
        [C(M(:,end)).NAICS_SECTOR]=deal(C(M(:,end)).NAICSTitle1997);
        maxyear(M(:,end))=1997;
        C=rmfield(C,'NAICSTitle1997');
      end
    end
    C=rmfield(C,'new__NAICS');
    S=C;
    if SHOWYEAR~=0
      maxY=num2cell(maxyear);
      [C.NAICS_YEAR]=deal(maxY{:});
      if SHOWYEAR==2
        C=rmfield(C,'NAICS_SECTOR');
      end
    end
    
  else
    error('not a field.')
  end
else
  error('duhhhh..nno.')
end
