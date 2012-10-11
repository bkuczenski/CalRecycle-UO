function S=assign(S,var,name)
% function S=assign(S,var)
%
% function S=assign(S,var,name)

if iscell(var)
  if length(var)==length(S)
    S.(inputname(2)) = var;
  else
    error('var and S not the same length');
  end
else
  if isnumeric(var) | islogical(var)
    var=num2cell(var);
  else
    error('Don''t know what to do.');
  end
end
switch nargin
  case 2
    [S.(inputname(2))] = deal(var{:});
  case 3
    [S.(name)] = deal(var{:});
  otherwise
    error('I''m very confused.');
end

      
  