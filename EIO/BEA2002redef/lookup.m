function n=lookup(src,word,index)
% lookup an entry by key (first column / NAICS)

if nargin<3
  index=1;
end

if isa(src,'struct')
  % assume it's a (domestic) data structure
  % recurse to both row and column
  n{1}=lookup(src.Rows,word,index);
  disp(['row: ' n(1) ])
  n{2}=lookup(src.Cols,word,index);
  disp(['col: ' n(2) ])
else
  n=find(~cellfun('isempty',regexpi(src(:,index),word)));
  if prod(size(n))>1
    disp('duplicate entry');
  elseif isempty(n)
    warning('No results found')
  end
end

