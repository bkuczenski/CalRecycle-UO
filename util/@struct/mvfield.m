function S=mvfield(S,O,N,flag)
% function S=mvfield(S,oldfield,newfield)
%
% Performs an in-place rename of a field of a one-dimensional structure array. 
% oldfield can be a field of S or an index into fieldnames.  newfield must be a
% string. 
%
% Will not rename over an existing field unless a fourth argument '-f' is
% supplied. 


FN=fieldnames(S);

if any(strcmp(FN,N))
  error(['Field ' N ' exists!'])
end
if isnumeric(O)
  Old=FN{floor(O)};
else
  Old=O;
  O=find(strcmp(FN,Old));
end
% O is index; Old is old fieldname

[S(:).(N)]=S.(Old);
S=rmfield(S,Old);
S=orderfields(S,[1:O-1 length(FN) O:length(FN)-1]);
