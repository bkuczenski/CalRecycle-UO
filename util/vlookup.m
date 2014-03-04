function [D,M]=vlookup(D,KeyField,RefTbl,RefField,varargin)
% function D=vlookup(D,KeyField,RefTbl,RefField,ReturnField)
%
% This performs an Excel-like table lookup on the contents of one table into
% another table (that's right, I'm using Matlab to craft an unholy blend of SQL
% and MS office).  The function runs through the entries in D.(KeyField), for each
% one locating a match in RefTbl(:).(RefField).  The corresponding entry in
% RefTbl.(ReturnField) is used to populate a new field in D.
%
% Entries for which no match was found in the RefTbl are populated with the
% contents of the corresponding KeyField.  To change this behavior, use 'blank'
% option.
%
% function D=vlookup(D,KeyField,RefTbl,RefField,ReturnField,args...)
% can be used to modify the function's behavior.  The following arguments are
% recognized: 
%
%  'inplace' - replace the contents of D.(KeyField) with the returned value,
%  instead of adding it into a new field.
%
%  'inexact' - like excel's not_exact_match arg; if no exact match is found,
%  return the nearest value that is less than the key value
%
%  'strdist' - for string KeyField values, return the result with the shortest
%  Levenshtein distance from the key value.  uses strnearest.m. 'first' implicit.
%
%  'strdistN' - where N is an integer - use strnearest with int arg limiting
%  distance. 
%
%  'oldstrdist' - use naive strdist algorithm
%
%  'blank'      - leave unmatched entries blank rather than filling them with
%  KeyField data.
%
%  'zero'       - assign unmatched entries the value of zero (or the empty string)
%  rather than filling them with KeyField data.
%
% The user must supply only enough of the argument to render it unambiguous
% (currently, 3 characters).
%
% An optional second argument will return a logical array indicating which entries
% did not match (this will be all 'true' for 'inexact' and 'strdist' lookups).

% first, process varargin
inplace=false;
blank=0;
match='exact';

while ~isempty(varargin)
  if ischar(varargin{1})
    if length(varargin{1})<3
      ReturnField=varargin{1};
    else
      switch varargin{1}(1:3)
        case 'exa'
          match='exact';
        case 'inp'
          inplace=1;
        case 'ine'
          match='inexact';
        case 'str'
          match='strdist';
          if ~isempty(regexp(varargin{1},'strdist[0-9]+'))
            shortest_arg=str2num(strrep(varargin{1},'strdist',''));
          else
            shortest_arg=[];
          end
        case 'old'
          match='oldstrdist';
        case 'fir'
          match='first';
        case 'bla'
          blank=1;
        case {'zer','spa'}
          blank=2;
        otherwise
          ReturnField=varargin{1};
      end
    end
  else
    disp('Don''t understand argument:')
    disp(varargin{1})
    keyboard
  end
  varargin(1)=[];
end

if isempty(D)
  disp('Empty input.')
  M=logical([]);
  return
end

if isempty(RefTbl)
  disp('Empty Ref Table')
  if ~isfield(D,ReturnField)
    switch blank
      case 0 % fill with keydata
        [D.(ReturnField)]=D.(KeyField);
      case 1 % leave blank
        [D.(ReturnField)]=deal([]);
      case 2 % zero
        [D.(ReturnField)]=deal(0);
    end
  end
  return
end

switch class(D(1).(KeyField))
  % delivers 'keys' and 'result'.  'keys' is a logical list of successful lookups;
  % 'result' is a list of indices into RtnData (sorted RefTbl)
  case 'double'
    K={D.(KeyField)};
    K(cellfun(@isempty,K))=deal({NaN});
    KeyData=cell2mat(K);
    [RefData,I]=sort([RefTbl(:).(RefField)]); % assume RefField is the same class 
    RtnData={RefTbl(I).(ReturnField)};

    result=nan(size(KeyData));

    % now fill in unmatched results if inexact matches are allowed
    switch match
      case 'exact'
        % first find exact matches: rows are RefData; cols are KeyData
        [matches,keys]=find(bsxfun(@eq,RefData(:),KeyData(:)'));
        result(keys)=matches;
      case 'inexact'
        % excel reports the nearest result that is lower than the key
        % RefData is already sorted, so we can use diff
        [matches,keys]=find(diff([bsxfun(@le,RefData(:),KeyData(:)');zeros(size(KeyData(:)'))]));
        result(keys)=matches;
      case 'strdist'
        error('Strdist not applicable to numeric data fields')
    end
    
  case 'char'
    KeyData={D(:).(KeyField)};
    [RefData,I]=sort({RefTbl(:).(RefField)}); % assume RefField is the same class 
    RtnData={RefTbl(I).(ReturnField)};

    result=nan(size(KeyData));

    % unfortunately- no bsxfun for cells
    switch match
      case {'exact','inexact'}
        %   celleq=cellfun(@strcmp,KeyData,repmat({RefData'},size(KeyData,1), ...
        %                                         size(KeyData,2)),'UniformOutput',0);
        %   [matches,keys]=find([celleq{:}]);
        %   result(keys)=matches;
        
        % case {'loop','inexact'}
        %   %error('Not implemented!')
        multi=[];
        for i=1:length(KeyData)
          r=bisect_find(KeyData{i},RefData); % finds nearest index
          % if length(r)>1
          %   disp(['  ambiguous match on KeyData ' KeyData{i}])
          %   multi=[multi i];
          %   r=r(1);
          % end
          if strcmp(match(1:2),'in') | (r>0 && strcmp(RefData(r),KeyData{i}))
            result(i)=r(1);
          end
          if mod(i,1000)==0 fprintf(1,'%d records processed\n',i); end
        end
        keys=find(~isnan(result));
        keys=setdiff(keys,multi);
      case 'strdist'

        %disp('Not implemented yet!')
        % use shortest_arg
        % RefData contains list of refs; KeyData contains list of keys
        if isempty(shortest_arg)
          d=strnearest(KeyData,RefData);
        else
          d=strnearest(KeyData,RefData,shortest_arg);
        end 
       
        multi=find(cellfun(@length,d)>1);
        for i=1:length(multi)
          disp(['  ambiguous match on KeyData ' num2str(multi(i))])
          d{multi(i)}=d{multi(i)}(1);
        end
        
        keys=~cellfun(@isempty,d);
        result(keys)=[d{find(keys)}];

%                keyboard

      case 'oldstrdist'
        d=strdist(KeyData,RefData); % returns a cell array of RefData-size arrays
        mins=cellfun(@find,cellfun(@eq,d,num2cell(cellfun(@min,d)), ...
                                   'UniformOutput',0),'UniformOutput',0);
        mins(cellfun(@length,mins)==length(RefData))=deal({[]}); % all-min means
                                                                 % no match
        multi=find(cellfun(@length,mins)>1); %multiple results- take the first
        for i=1:length(multi)
          disp(['  ambiguous match on KeyData ' num2str(multi(i))])
          mins{multi(i)}=mins{multi(i)}(1);
        end
        % for all others, take the first match
        keys=~cellfun(@isempty,mins);
        matches=[mins{keys}];
        
        result(keys)=matches;
    
        % now we mess with keys to have M contraindicate ambiguous as well 
        % as un-matching records
        keys(multi)=false;
      case 'first'
        % take first match- slower than bisect-find
        multi=[];
        for i=1:length(KeyData)
          r=find(strcmp(KeyData{i},RefData)); % finds nearest index
          if length(r)>1
            disp(['  ambiguous match on KeyData ' KeyData{i}])
            multi=[multi i];
            r=r(1);
          end
          if strcmp(match(1:2),'in') | strcmp(RefData(r),KeyData{i})
            result(i)=r(1);
          end
          if mod(i,1000)==0 fprintf(1,'%d records processed\n',i); end
        end
        keys=find(~isnan(result));
        keys=setdiff(keys,multi);
    end
    
    %     % now fill in unmatched results if inexact matches are allowed
%     switch match
%       case 'exact'
%         % first find exact matches: rows are RefData; cols are KeyData
%         [matches,keys]=find(bsxfun(@eq,RefData(:),KeyData(:)'));
%         result(keys)=matches;
%       case 'inexact'
%         % excel reports the nearest result that is lower than the key
%         % RefData is already sorted, so we can use diff
%         [matches,keys]=find(diff([bsxfun(@le,RefData(:),KeyData(:)');zeros(size(KeyData(:)'))]));
%         result(keys)=matches;
%       case 'strdist'
%         error('Strdist not applicable to numeric data fields')
%     end
    
  otherwise
    disp('Don''t know how to match this:')
    disp(KeyData{1})
end

% now assign the results to the desired field

% if isnumeric(RtnData{1})
%   badresult=NaN;
% else
%   badresult='N/A';
% end

if inplace
  DestField=KeyField;
else
  DestField=ReturnField;
end


[OutData{~isnan(result)}]=RtnData{result(~isnan(result))};
switch blank
  case 0
    if iscell(KeyData)
      [OutData(isnan(result))]=KeyData(isnan(result));
    else
      [OutData(isnan(result))]=deal({KeyData(isnan(result))});
    end
    [D(:).(DestField)]=deal(OutData{:});
  case 1 % leave blank / NaN
    [D(~isnan(result)).(DestField)]=deal(OutData{~isnan(result)});
  case 2 % fill with zeros
    if isnumeric(RtnData{1}) & ~isempty(RtnData{1})
      [OutData(isnan(result))]=deal({0});
    else
      [OutData(isnan(result))]=deal({' '});
    end
    [D(:).(DestField)]=deal(OutData{:});
end


M=logical(zeros(size(D)));
M(keys)=true;
% easy-peasy.
