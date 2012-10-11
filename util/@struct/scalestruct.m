function s=scalestruct(s,fact,excl)
% function s=scalestruct(s,fact)
% scale all numeric data in a structure by a fixed factor, recursively.
%
% function s=scalestruct(s,fact,excl)
% same as above, but excl is a cell-array of field names to not scale.
if nargin<3
  excl={};
end

debug=1;

FN=fieldnames(s);
for i=1:length(FN)
  if any(strcmp(FN{i},excl))
    % skip this
    if debug fprintf('Skipping Field %s\n',FN{i}); end
  elseif isstruct([s.(FN{i})])
    if debug fprintf('Recursing into structure %s\n',FN{i}); end
    s.(FN{i})=scalestruct(s.(FN{i}),fact,excl);
  elseif isnumeric([s.(FN{i})])
    k=find(~cellfun(@isempty,{s.(FN{i})}));
    q=num2cell([s(k).(FN{i})]*fact);
    try
      [s(k).(FN{i})]=deal(q{:});
    catch
      keyboard
    end
  else
    if debug fprintf('non-numeric field %s\n',FN{i}); end
    % nothing to do
  end
end
