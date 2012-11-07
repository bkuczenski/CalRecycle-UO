function s=ifnum2str(varargin)
% function s=ifnum2str(x)
% /usr/local/Matlab2011b/R2011b/toolbox/matlab/strfun/num2str.m
% if s is already a char, just return
if ischar(varargin{1})
  s=varargin{1};
else
  s=num2str(varargin{:});
end
