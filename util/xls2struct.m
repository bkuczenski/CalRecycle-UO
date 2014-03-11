function S=xls2struct(xlsfile,worksheet,fmt)
% function S=xls2struct(xlsfile,worksheet,fmt)
% Read data from an excel worksheet into a structure array.  The first row must
% contain valid matlab structure field names (e.g. [A-Za-z][_A-Za-z0-9]*) fmt is a
% cell array of format specifiers, each corresponding to one column of data.
%
% Currently supported format specifiers are:
%  'n' - numeric data
%  'ND' - numeric data, replacing the string 'ND' with NaN
%  's' - string data
%  ''  - skip this column
%
% All arguments are required.  If fmt is not specified, the resulting structure
% will simply include the output of xlsread for every column that has a nonzero
% first entry.

[~,~,C]=xlsread(xlsfile,worksheet);
C=ccrop(C);

FN=tr(C(1,:),' ()/-#','_____N');
Dat=C(2:end,:);

% identify valid columns manually
nvalid=cellfun(@ischar,FN); 
valid=num2cell(double(nvalid)); 
valid(find(nvalid))=regexp(FN(nvalid),'^[A-Za-z][_A-Za-z0-9]*$');
[valid(cellfun(@isempty,valid))]=deal({0}); % cell form
nvalid=cell2mat(valid); % numeric form

if nargin<3
  fmt=valid;
end
for i=1:length(fmt)
  switch(fmt{i})
    case 'n'
      Dat(:,i)=num2cell(cellfun(@ifstr2num,Dat(:,i)));
    case 'ND'
      Dat(find(strcmp(Dat(:,i),'ND')),i)=deal({NaN});
      try
      Dat(:,i)=num2cell(cellfun(@ifstr2num,Dat(:,i)));
      catch
        fprintf('xls2struct: Poorly conditioned data in column %d: %s\n',i,FN{i})
        keyboard
      end
    case 's'
      notchar=find(~cellfun(@ischar,Dat(:,i)));
      notan=logical(zeros(size(Dat(:,i))));
      notan(notchar(cellfun(@isnan,Dat(notchar,i))))=true;
      [Dat(notan,i)]=deal({''});
      Dat(:,i)=cellfun(@ifnum2str,Dat(:,i),'uniformoutput',false);
    case ''
      nvalid(i)=0;
    case 0
      fprintf('Dropping column %d: invalid field name\n',i)
    otherwise
      % nothing to do-- accept as is
      fprintf('Warning: column %d consistency not checked\n',i)
  end
end
nvalid(length(fmt)+1:end)=0;
FN=FN(find(nvalid));
Dat=Dat(:,find(nvalid));
S=cell2struct(Dat',FN);

  