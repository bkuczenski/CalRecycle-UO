function F=read_dat(filename,delim,fmt,filt)
% this function reads a delimited data file into a structure array.  The first
% line of the file is used to determine both the number of fields and the field
% names. 
%
% read_dat(filename,delim) allows the user to specify the delimiter (should be a
% character string or regular expression; default is '\t' for tab).
%
% read_dat(filename,delim,fmt) also allows the user to specify a list of format
% strings.  The argument 'fmt' must be a cell array.  Format strings should fit
% the following regexp:
%
% q?[sSiILn]
%
% where 's' indicates a character string (the default); 'd' indicates a number (empty
% to 0) and 'n' indicates a number (empty to NaN).  double-quotes are automatically
% filtered out (and their sense is ignored: quoted delimiters are not escaped).
%
% deprecated: 'i' indicates an int16; 'I' int32; 'L' int64.  The optional 'q' is
% ignored silently. (formerly told the function to strip the first and last character
% of the field (as quotes)).  An empty value '' indicates that the field should be
% skipped.  
%
% The default format is 's'.  String-formatted entries are automatically deblanked
% (trailing blanks).'S' is like 's' except suppresses deblanking. 
%
% For numeric fields ('u' and 'n'), commas ',' are taken to be 1,000 delimiters
% and are removed.  If a noninteger is found in a 'u'-specified field, an error
% will result. (possible resolution: truncation?)
%
% If the fmt argument is shorter than the number of fields, the last supplied value
% (or the default) will be used for all remaining fields.  If fmt is longer,
% extraneous entries will be ignored.
%
% read_dat(filename,delim,fmt,filt) allows the user to specify a record filter.  The
% filter should be a structure array with the fields 'Field', 'Test', and
% 'Pattern'.  See @struct/filter.m for details.
%
% After reading and processing each record, after the above format strings have
% been applied. 
%
% The function will run through all tests sequentially.  All tests must be
% satisfied for the record to pass the filter.
%

if nargin<4 filt=struct([]); end
if nargin<3 fmt={'s'}; end
if ~isa(fmt,'cell') fmt={fmt}; end
if nargin<2 delim='\t'; end
if nargin<1
  filename=ifinput('Enter file name: ','chem_com.dat','s');
end

fid=fopen(filename);
numlines=0;
while(fgetl(fid)~=-1)
  numlines=numlines+1;
end
fclose(fid);

fid=fopen(filename);
L=fgetl(fid);

if isempty(L)
  disp('Empty file?')
  keyboard
end

FieldNames=regexp(L,delim,'split');

for i=length(FieldNames):-1:1 % reverse order because we may drop fields
  myfmt=fmt{min([length(fmt),i])};
  if isempty(myfmt) FieldNames(i)=[];  % drop '' fields entirely
  else 
    FieldNames{i}( FieldNames{i}==' ' )=''; % remove spaces from retained fields
    FieldNames{i}( FieldNames{i}=='"' )=''; % remove quotes from retained fields
  end
  FieldNames{i}=tr(FieldNames{i},'-,.:;','_____');
end
%keyboard
FN=[FieldNames;FieldNames];

F=struct(FN{:});
% reserve memory
F(numlines)=F(1);

NumRecords=0;
NRA=0;

L=fgetl(fid);
while isempty(L) L=fgetl(fid); end
  
while L~=-1
  NumRecords=NumRecords+1;
  Data=regexp(L,delim,'split');

  % Data Format processing
  for i=length(Data):-1:1 % reverse order because we may drop fields
    myfmt=fmt{min([length(fmt),i])};
    if isempty(myfmt) Data(i)=[];
    else
      thisdata=Data{i};
      if myfmt(1)=='%' myfmt=myfmt(2:end); end % strip leading %
      if myfmt(1)=='q' 
%        warning('Blindly truncating..')
%        thisdata=thisdata(2:end-1);
        %        tok=regexp(Data{i},'^"([^"]+)"$','tokens');
%         if isempty(tok)
%           Data{i}='';
%         else
%           try
%             Data{i}=tok{1}{1};
%           catch
%             disp(NumRecords)
%             disp(i)
%             keyboard
%           end
%         end
        myfmt=myfmt(2:end);
      end
      thisdata( thisdata=='"' )=''; % strip csv-introduced doublequotes
      switch myfmt(1)
        case 'i'
          % implicit: comma for 000 separator removed
          thisdata( thisdata==',' )='';
          thisdata=int16(str2double(thisdata));
        case 'I'
          % implicit: comma for 000 separator removed
          thisdata( thisdata==',' )='';
          thisdata=int32(str2double(thisdata));
        case 'L'
          % implicit: comma for 000 separator removed
          thisdata( thisdata==',' )='';
          thisdata=int64(str2double(thisdata));
        case 'n'
          % implicit: comma for 000 separator removed
          try
            thisdata( thisdata==',' )='';
          catch
            disp(i)
            keyboard
          end
          thisdata=str2double(thisdata);
        case 'd'
          thisdata=str2double(thisdata);
          thisdata(isnan(thisdata))=0;
        case 'S' 
          % strings- no deblank- do nothing
        otherwise
          % strings- no change except:
          thisdata=deblank(thisdata);
      end
      Data{i}=thisdata;
    end
  end
  try
    Data=Data(1:length(FieldNames));
  catch
    fprintf('%d: not enough data fields?\n',NumRecords)
    keyboard
  end
  try
    FN=[FieldNames;Data];
  catch
    fprintf('%d: too many data fields [freak error]?\n',NumRecords)
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
      NRA=NRA+1;
      F(NRA+1)=Ft;
    end
  else
    NRA=NRA+1;
    F(NRA+1)=Ft;
  end
  
  if mod(NumRecords,1000)==0
    disp([num2str(NumRecords) ' records Processed ; ' ...
          num2str(NRA) ' records Accepted ... '])
  end

%  if NumRecords==4000 break; end
  
  L=fgetl(fid);
end

F=F(2:NRA+1); % get rid of header entry

disp([num2str(NumRecords) ' records Processed ; ' ...
      num2str(length(F)) ' records Accepted.'])
fclose(fid);
