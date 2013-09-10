function P=pivot(S,R,C,D,varargin)
% function P=pivot(SOURCE,ROW,COL,DATA,varargin)
% Prints a pivot table to the Matlab command window and returns a 2d data
% structure of the sort used in the EIO work.  Row metadata, column metadata,
% data.
%
% function P=pivot(S,R,C,D) creates a pivot table with named column R as the
% horizontal heading and named column C as the vertical heading.  D can be a named
% column or a cell array of named columns (or ideally a double array of column
% indices) for which data are reported at each row and column.
%
% function P=pivot(S,R,C,D,Rsub,Csub) allows the user to filter the source table
% according to the constraints set out in Rsub and Csub.  Blank  or empty = no
% filter.  For now, the contents of R and C are assumed to be strings, and the
% constraints are interpreted as regexps.  If Rsub or Csub is a 2-element cell
% array, the first element is taken to be the regexp and the second element the
% inversion specifier.  If Rsub or Csub is a 3-element cell array, the first
% element is taken to be the function (instead of regexp); the second argument the
% pattern; the third argument the inversion specifier.
%
% if nargout==0, pretty prints the result using dispData-inspired fprintf, with some
% tricks for when D is an array.
%
% NOTE: currently fills non-entries with NaNs, which could lead to collisions if
% the data actually contain NaNs.  Advised not to use this function with data
% containing NaN.

% now add in 6-arg case
if nargin>4
  if ~isempty(varargin{1})
    S=subfilter(S,R,varargin{1});
  end
  if nargin>5
    if ~isempty(varargin{2})
      S=subfilter(S,C,varargin{2});
    end
  end
end

% just do 4-arg case first
if ~iscell(R) R={R}; end
if ~iscell(C) C={C}; end
for i=1:length(R)
  if isnumeric(firstnonzero(S,R{i}))
    S=moddata(S,R{i},@num2str);
  end
end
for i=1:length(C)
  if isnumeric(firstnonzero(S,C{i}))
    S=moddata(S,C{i},@num2str);
  end
end

% last, allow multiple R+C
[S,R]=combine(S,R);
[S,C]=combine(S,C);

Rows=sort(unique({S.(R)}));
Cols=sort(unique({S.(C)}));

r_ind=ind_lookup({S.(R)},Rows);
c_ind=ind_lookup({S.(C)},Cols);

if ~iscell(D)
  D={D};
end
for k=1:length(D)
  data{k}=nansparse(r_ind,c_ind,[S.(D{k})]);
  dm{k}=max(sum(data{k}));
end

if nargout==0
  %full display 

  % determine max field widths
  FW=max([15,5+ceil(log10(max([dm{:}])))]); % 13
  HW=max(cellfun(@length,[Rows R])); % 15

  fprintf('%*s: ',HW,C)
  for i=1:length(Cols)  fprintf('%*s ',FW-1,Cols{i}) ; end
  fprintf('\n');
  fprintf('%-*s +',HW,R)
  for i=1:length(Cols) fprintf('%s',repmat('-',1,FW)) ; end
  fprintf('\n');
  for j=1:length(Rows)
    for k=1:length(D)
      if k==1
        fprintf('%*s |',HW,Rows{j})
      else
        fprintf('%*s |',HW,'')
      end
      for i=1:length(Cols)  fprintf('%*g  ',FW-2,data{k}(j,i)) ; end
      %fprintf('%s\n',rName{I(j)});
      fprintf('%*g  %s\n',FW-2,...
              sum(data{k}(j,~isnan(data{k}(j,:)))),D{k});
    end
    if k>1
      % print separator
      fprintf('%-*s +',HW,'')
      for i=1:length(Cols) fprintf('%*s',FW,'') ; end
      fprintf('\n');
    end
  end
  % if num<DB.NumRows % display remainder
  %   fprintf('    %-10s |','')
  %   for i=1:DB.NumCols  fprintf('%9g  ',sum(cData(I(num+1:end),i))) ; end
  %   fprintf('%s\n','Remainder');
  % end
  
  if length(Rows)>1
    fprintf('Totals:\n');
    fprintf('%-*s +',HW,'')
    for i=1:length(Cols) fprintf('%s',repmat('-',1,FW)) ; end
    fprintf('\n');
    for k=1:length(D)
      fprintf('%-*s |',HW,D{k})
      for i=1:length(Cols) 
        fprintf('%*.*g  ',FW-2,FW-2,sum(data{k}(~isnan(data{k}(:,i)),i))); 
      end
      fprintf('\n');
    end
  end
end % if nargout ==0
  
P.Rows=Rows;
P.Cols=Cols;
P.Fields=D;
P.Data=data;




function ind=ind_lookup(key,value)

if iscell(key)
  funfun=@strcmp;
else
  funfun=@eq;
end

for i=1:length(key)
  ind(i)=find(funfun(key{i},value));
end


    
function S=subfilter(S,R,Rsub)
if iscell(Rsub)
  switch length(Rsub)
    case 1
      S=filter(S,R,{@regexp},Rsub{1});
    case 2
      S=filter(S,R,{@regexp},Rsub{1},Rsub{2});
    case 3
      S=filter(S,R,Rsub{1},Rsub{2},Rsub{3});
    otherwise
      error('Don''t understand subset specification.')
  end
else
  S=filter(S,R,{@regexp},Rsub);
end


function [S,R]=combine(S,R)
if iscell(R)
  if length(R)>1
    Rn=[sprintf('%s_',R{1:end-1}) R{end}];
    for i=1:length(S)
      S(i).(Rn)=[sprintf('%s_',S(i).(R{1:end-1})) S(i).(R{end})];
    end
    S=rmfield(S,R);
    R=Rn;
  else
    R=R{1};
  end
end


function c=firstnonzero(D,F)
c=NaN;
k=1;
while k<=length(D)
  if ~isempty(D(k).(F))
    if isnumeric(D(k).(F))
      if D(k).(F)~=0
        c=D(k).(F);
        break
      end
    else
      c=D(k).(F);
      break
    end
  end
  k=k+1;
end

function D=nansparse(row,col,dat)
D=nan(max(row),max(col));
for i=1:length(dat)
  if isnan(D(row(i),col(i)))
    D(row(i),col(i))=dat(i);
  else
    D(row(i),col(i))=D(row(i),col(i))+dat(i);
  end
end
