function O = lookup(S,val,in,out)
% function O = lookup(S,val,in,out)
%
% Lookup 'val' into column 'in' of structure S; return entry from column 'out'
if isnumeric(val)
  O=getfield(filter(S,in,{@eq},val),out);
else
  O=getfield(filter(S,in,{@strcmp},val),out);
end
  
