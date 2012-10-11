function IOData=bea_read(filename);
% function!
%%%%% script file to read BEA IOUseDetail.txt into a data structure

% Structure of file:
% header line: columns are whitespace-delimited
% 
%    'Commodity'              NAICS specification
%    'CommodityDescription'   whitespace-careless 
%    'Industry'    'IndustryDescription'
%     'ProVal'
%     'StripMar'
%     'RailVal'
%     'TruckVal'
%     'WaterVal'
%     'AirVal'
%     'PipeVal'
%     'GasPipeValWhsVal'  * needs manual editing: add whitespace before WhsVal
%     'RetVal'
%     'PurVal'
%     'IOYear'
%
% too big to read in at once
% lots of redundant information;
% probably sparse
% so first scan the file reading a list of industries [and commodities; but I
% suspect they are the same] based on NAICS as unique key- assumption that they
% are strictly sequential in the first column
% and then rescan the file, ignore the text, and assign the data into a 3d matrix
% nxnx11
%
% the list of sectors - that nx2 ID-to-description- is an important data point.
%
% the ID being the economic (not industrial!) ID: Commodity code or industry
% specification

if nargin==0 filename='IOUseDetail.txt' ; end

IOData.filename=filename;
fid=fopen(filename);

% first line is structure fields
NextLine=fgetl(fid);
Names=strread(NextLine,'%s');

% determine metadata
IOData.RowHeading={Names{1},Names{2}}
IOData.ColumnHeading={Names{3},Names{4}}
IOData.Quantities=Names(5:end-1);
IOData.NumQuantities=length(IOData.Quantities);

IOData.Rows={};
IOData.Cols={};

dbcount=0;

tic
NextLine=fgetl(fid);
while ischar(NextLine)
  dbcount=dbcount+1;
  toks=strread(NextLine,'%s');
  D{1}=toks{1};toks=toks(2:end);
%  keyboard
  [D{2},E{1},toks]=grabname(toks);
  [E{2},foo,toks]=grabname(toks);
  
  IOData.Rows=alphabetize(IOData.Rows,D); % faster than appendnew
  IOData.Cols=alphabetize(IOData.Cols,E);
%  pause
  NextLine=fgetl(fid);
  if mod(dbcount,2000)==0 disp(['Count = ' num2str(dbcount) ...
                        '; Rows: ' num2str(size(IOData.Rows,1)) ... 
                        '; Cols: ' num2str(size(IOData.Cols,1)) ... 
                   ]); toc;tic;end
end

fclose(fid);
toc
disp(['Total Count = ' num2str(dbcount) ...
                        '; Rows: ' num2str(size(IOData.Rows,1)) ... 
                        '; Cols: ' num2str(size(IOData.Cols,1)) ... 
                   ]); 

% so now we have sorted lists of commodities (including government and value-added);
% and industries (including government and final demand)

IOData.Year=Names(end);

IOData.NumRecords=dbcount;
IOData.NumRows=size(IOData.Rows,1);
IOData.NumCols=size(IOData.Cols,1);


% end -----------------------------------------------------------------

  

function A=appendnew(A,tok)
if isempty(A)
  A=tok;
else
  if ~any(ismember(A(:,1),tok(1)))
    A=[A;tok];
  end
end





function t=isaNAICS(g)
% returns true if g is a NAICS specification: 6-8 digits, all numbers and
% uppercase letters
t=logical(~isempty(regexp(g,'[A-Z0-9]{6,8}')));

