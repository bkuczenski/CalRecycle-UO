function D=write(s,excl,pre)
% function D=write(s)
% function D=write(s,excl)
% Writes out all terminal nodes of s, optionally excluding fields listed in cell
% array 'excl'.  

if nargin<3 pre=inputname(1); end
if nargin<2 excl={}; end

debug=0;
D={};

FN=fieldnames(s);
for i=1:length(FN)
  if any(strcmp(FN{i},excl))
    % skip this
    if debug fprintf('Skipping Field %s\n',FN{i}); end
    Di={};
  elseif isstruct([s.(FN{i})])
    if debug fprintf('Recursing into structure %s\n',FN{i}); end
    Di=write(s.(FN{i}),excl,[pre '.' FN{i}]);
  else
    Di=sprintf('%s.%s',pre,FN{i});
    % nothing to do
    fprintf('%s\n',Di);
  end
  D=[D;Di];
end
