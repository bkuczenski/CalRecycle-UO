function [S,newfield]=concat(S,field1,varargin)
% function S=concat(S,{field1,field2...},dlm)
%
% Concatenates the contents of field1 and field2 (and ...) with intervening
% delimiter.  Numeric fields are first converted to strings.  The fields are removed
% and replaced with a single field whose name is [field1 '_' field2].  If dlm is
% omitted, the default delimiter is '+'.
%
% function S=concat(S,field1,field2,[dlm])
%
% function S=concat(S,field1,field2,...,[dlm])
% concatenates multiple fields.
%
% [S,FN]=concat(...) returns the name of the new field

if iscell(field1)
  if nargin<3
    dlm={'+'};
  else
    dlm=varargin{1};
  end
  if length(varargin)>1
    error('Don''t know what to do with extra arguments')
  end
  if ~iscell(dlm)
    dlm={dlm};
  end
  if length(field1)==1
    error('Must supply at least two fields.')
  else
    % base case
    if checknumeric(S,field1{1})
      S=moddata(S,field1{1},@num2str);
    end
    if checknumeric(S,field1{2})
      S=moddata(S,field1{2},@num2str);
    end
    d=strcat({S.(field1{1})}',dlm(1),{S.(field1{2})}');
    [S(:).(field1{1})]=deal(d{:});
    newfield=[field1{1} '_' field1{2}];
    S=mvfield(S,field1{1},newfield);
    S=rmfield(S,field1{2});
    if length(field1)>2
      if length(dlm)<2 dlm=[dlm dlm]; end
      [S,newfield]=concat(S,{newfield,field1{3:end}},dlm(2:end));
    end
  end
else
  if nargin==2
  else
    if isfield(S,varargin{end})
      % no dlm provided
      [S,newfield]=concat(S,{field1,varargin{:}},'+');
    else
      [S,newfield]=concat(S,{field1,varargin{1:end-1}},varargin{end});
    end
  end
end

    
      
function t=checknumeric(S,field)
j=1;
while isempty(S(j).(field))
  if j==length(D) break; end
  j=j+1;
end
t=isnumeric(S(j).(field));
