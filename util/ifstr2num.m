function [x,ok]=ifstr2num(s)
% function [x,ok]=ifstr2num(s)
% /usr/local/Matlab2011b/R2011b/toolbox/matlab/strfun/str2num.m
% if s is already a num, just return
if isnumeric(s)
  x=s;
  ok=true;
else
  [x,ok]=str2num(s);
end
