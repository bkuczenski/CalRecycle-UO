function [ND,mytok,toks]=grabname(toks)
% function [ND,mytok,toks]=grabname(toks)
% gobbles toks until it finds one that contains numbers.  
% Returns the gobbled toks as ND and the [alpha]numeric one as mytok.
ND='';
while 1
  mytok=toks{1};toks=toks(2:end);
  if regexp(mytok,'^\D+$') % no digits in descriptions?
    ND=[ND mytok ' ' ];
  else
    ND=ND(1:end-1);
    break; end
end
