function out=dispData(DB,dataset,col,num)
% function dispData(DB,dataset)
%
% fprints the data in a pretty table.  if dataset is omitted, assume 1.
%
% function dispData(DB,dataset,col)
%
% sorts the data along column 'col', where 0 = row NAICS, 1-n = col, n+1 = row
% Name.  n=DB.NumCols.  Sorts NAICS or Name ascending; data descending.
%
% function dispData(DB,dataset,col,num)
%
% Limits output to num rows.

if nargin<2   dataset=1; end

rNAICS=DB.Rows(:,1);
rName=DB.Rows(:,2);
cNAICS=DB.Cols(:,1);
cName=DB.Cols(:,2);
cData=full(DB.Data{dataset});

if nargin<3
  [D,I]=sort(rNAICS);
else
  if col>DB.NumCols
    [D,I]=sort(rName);
  elseif col>0
    [D,I]=sort(cData(:,col),'descend');
  else
    [D,I]=sort(rNAICS);
  end
end

if nargin<4
  num=length(I);
else
  num=min([num,length(I)]);
end
      

disp([DB.ColumnHeading{2} ' (columns):'])
for i=1:length(cName) fprintf(' %-10s %s\n',cNAICS{i},cName{i}) ; end
fprintf('\n');
disp([DB.RowHeading{1} '-by-' DB.ColumnHeading{1} ' -- ' DB.Quantities{dataset} ...
      ' -- ' DB.filename ])

% % NAICS-only
% fprintf('%15s:    ',DB.ColumnHeading{1})
% for i=1:length(MC)  fprintf(' %-10s',cNAICS{i}) ; end
% fprintf('\n');
% fprintf('%-15s +',DB.RowHeading{1})
% for i=1:length(MC) fprintf('-----------') ; end
% fprintf('\n');
% for j=1:length(MR)
%   fprintf('    %-10s  |',rNAICS{j})
%   for i=1:length(MC)  fprintf('%10g ',cData(j,i)) ; end
%   fprintf('\n');
% end
% fprintf('\n');
% disp([DB.RowHeading{2} ' (rows):'])
% for i=1:length(rName) fprintf(' %-10s %s\n',rNAICS{i},rName{i}) ; end

out=[];

%full display 
fprintf('  %10s:  ',DB.ColumnHeading{1})
for i=1:DB.NumCols  fprintf(' %10s',cNAICS{i}) ; end
fprintf('\n');
fprintf('%-15s+',DB.RowHeading{1})
for i=1:DB.NumCols fprintf('-----------') ; end
fprintf('\n');
for j=1:num
  fprintf('    %-10s |',rNAICS{I(j)})
  for i=1:DB.NumCols  fprintf('%9g  ',cData(I(j),i)) ; out(j,i)=cData(I(j),i); end
  fprintf('%s\n',rName{I(j)});
end
if num<DB.NumRows % display remainder
  fprintf('    %-10s |','')
  for i=1:DB.NumCols  fprintf('%9g  ',sum(cData(I(num+1:end),i))) ; end
  fprintf('%s\n','Remainder');
end

fprintf('\n');
if DB.NumRows>1
  fprintf('  %-10s   +','')
  for i=1:DB.NumCols fprintf('-----------') ; end
  fprintf('\n');
  fprintf('    %-10s |','TOTAL:')
  for i=1:DB.NumCols fprintf('%9g  ',sum(cData(:,i))) ; end
  fprintf('\n');
end


