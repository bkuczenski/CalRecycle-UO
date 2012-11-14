function s=qq(DB,row,col,dataset)
% function s=qq(DB,row,col,dataset)
% quick query of DB.  provide row spec, col spec.  if one or the other is 'any',
% substitute ':' in the lookup.  no nargout, pretty-print with sprintf.  with
% nargout.. to be continued
%
% if row/col spec is a string other than 'any', use it as a lookup.  if it isaNAICS,
% lookup first column; else lookup second column.  
%
% for now, only row lookup is supported

if nargin<4 dataset=1; end
if nargin<3 col='any'; end
if nargin<2 warning('need row or col specification') ; disp(DB); return; end
wild=0;

if ischar(row)
  if strcmp(row,'any')|isempty(row)
    MR=1:size(DB.Data{dataset},1);
    wild=1;
  elseif isaNAICS(row)
    MR=lookup(DB.Rows,row,1);
  else
    MR=lookup(DB.Rows,row,2);
  end
else
  MR=row;
end

if ischar(col)
  if strcmp(col,'any')|isempty(col)
    MC=1:size(DB.Data{dataset},2);
    wild=wild+2;
  elseif isaNAICS(col)
    MC=lookup(DB.Cols,col,1);
  else
    MC=lookup(DB.Cols,col,2);
  end
else
  MC=col;
end

if wild>0
  % pare down sparsity
  [MRi,MCi]=find(DB.Data{dataset}(MR,MC));
  if bitand(wild,1) % wild row
    MR=MR(unique(sort(MRi)));
  end
  if bitand(wild,2) % wild row
    MC=MC(unique(sort(MCi)));
  end
end

%keyboard

s=DB;
s.Rows=DB.Rows(MR,:);
s.Cols=DB.Cols(MC,:);
s.NumRows=length(MR);
s.NumCols=length(MC);
for i=1:s.NumQuantities
  s.Data{i}=s.Data{i}(MR,MC);
end

if nargout==0 dispData(s,dataset); end

function t=isaNAICS(g)
% returns true if g is a NAICS specification: 6-8 digits, all numbers and
% uppercase letters
t=logical(~isempty(regexp(g,'[A-Z0-9]{1,8}')));

  
    
