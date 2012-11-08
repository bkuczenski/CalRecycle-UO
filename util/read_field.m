function F=read_field(filename,names,widths,fmt,filt)
% function F=read_field(filename,names,widths)
% Mon 10-01 22:30:38
% 
% Reads data from a file with width-delimited fields.  'names' should be the names of
% each field (cell array).  if 'names' is empty, tries to read comma-delimited data
% from the first line of filename.  If a given element of 'names' is empty, that
% entry is skipped.
%
% 'widths' should be a numeric array of integer
% fieldwidths.  Once the total characters indicated by sum(widths) has been read, the
% rest of the line is discarded.
%
% function F=read_field(filename,names,widths,fmt) 
% 
% 'fmt' is a char or cell array indicating 's' for string, 'n' for number, for each
% field.  Default is to assume strings.  NOTE: if blank entries in 'names' lead to
% some columns being skipped, those columns should still be included in the 'fmt'
% specification, but will be ignored.
%
% function F=read_field(filename,names,widths,fmt,filt) allows the user to specify a
% record filter.  The filter should be a structure array with the fields 'Field',
% 'Test', and 'Pattern'.  See @struct/filter.m for details.
%

% Tue 10-02 00:14:16; but that was with a >60min FreeBSD detour


if length(names)~=length(widths)
  error('names and widths must be the same length')
end
if nargin<5 filt={}; end
if nargin<4 | isempty(fmt) fmt={'s'}; end
if ~iscell(fmt) fmt={fmt}; end

fid=fopen(filename);

if isempty(names)
  disp(['Attempting to read comma-delimited heading names from ' filename]);
  L=fgetl(fid);

  if isempty(L)
    disp('Empty file?')
    keyboard
  end
  
  names=regexp(L,',','split');
end

FieldNames=names(~cellfun(@isempty,names));

FN=[FieldNames;FieldNames];

F=struct(FN{:});
NumRecords=0;

L=fgetl(fid);
while isempty(L) L=fgetl(fid); end
  
while L~=-1
  NumRecords=NumRecords+1;
  Data=break_string(L,widths);
  for i=1:length(names)
    if strcmp(fmt{min([i,length(fmt)])},'n')
      Data{i}=str2num(Data{i});
    end
  end
  Data=Data(~cellfun(@isempty,names));
  try
    FN=[FieldNames;Data];
  catch
    disp('Freak error')
    disp(NumRecords)
    keyboard
    FN=[FieldNames;Data];
  end
  Ft=struct(FN{:}); % candidate record

  % Record filtering
  if ~isempty(filt)
    % try
    %   filter(Ft,filt)
    % catch
    %   keyboard
    % end
    
    if ~isempty(filter(Ft,filt))
      F(end+1)=Ft;
    end
  else
    F(end+1)=Ft;
  end
  
  if mod(NumRecords,1000)==0
    disp([num2str(NumRecords) ' records Processed ; ' ...
          num2str(length(F)-1) ' records Accepted ... '])
  end

%  if NumRecords==4000 break; end
  
  L=fgetl(fid);
end

F=F(2:end); % get rid of header entry

disp([num2str(NumRecords) ' records Processed ; ' ...
      num2str(length(F)) ' records Accepted.'])
fclose(fid);
