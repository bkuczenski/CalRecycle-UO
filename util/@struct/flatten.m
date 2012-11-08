function D=flatten(s,excl,pre)
% function S=flatten(s)
% Writes out all terminal nodes of s to a new non-hierarchical structure array.
%
% function S=write(s,excl)
% optionally excludes fields listed in cell array 'excl'.  


if nargin<3 pre=inputname(1); end
if nargin<2 excl={}; end

debug=1;
D=struct('Key',{},'Value',{});

FN=fieldnames(s);
for i=1:length(FN)
  Di={};
  if any(strcmp(FN{i},excl))
    % skip this
    if debug fprintf('Skipping Field %s\n',FN{i}); end
  elseif isstruct([s.(FN{i})])
    if debug fprintf('Recursing into structure %s\n',FN{i}); end
    Di=flatten(s.(FN{i}),excl,[pre '.' FN{i}]);
  else
    Di{1}=sprintf('%s.%s',pre,FN{i});
    Di{2}=s.(FN{i});
    Di=cell2struct(Di',{'Key','Value'});
    if debug fprintf('Done : %s.%s\n',pre,FN{i}); end
    %fprintf('%s\n',Di);
  end
%  keyboard;
  D=[D;Di];
end

