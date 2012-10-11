function S=tr(S,in,out);
% function S=tr(S,in,out);
% Converts characters in 'in' to characters in 'out' for input strings S.
% 'in' and 'out' should be strings of characters of equal length.  S can be a
% string or a cell array of strings.
% 
% If 'out' is longer than 'in', certain translations will not get used.  If 'in'
% is longer than 'out', translations beyond the last one provided in 'out' will be
% replaced with the empty string.

if iscell(in) in=[in{:}]; end
if iscell(out) out=[out{:}]; end

if iscell(S)
  for i=1:length(S)
    S{i}=tr(S{i},in,out);
  end
else
  for i=1:length(in)
    if i>length(out)
      S=strrep(S,in(i),'');
    else
      S=strrep(S,in(i),out(i));
    end
  end
end
