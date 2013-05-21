function [Y,I]=sort(X,field,mode)
% @struct/function [Y,I]=sort(X,field,mode)
%
% Sorts a structure array by field.  Don't know why I have to write this myself.

if nargin<3 mode='ascend'; end
if nargin<2 field=1; end
if length(X)==1
  Y=X;
  I=1;
  return
end

FN=fieldnames(X);

if ~isnumeric(field)
  field=find(strcmp(FN,field));
end

if isnumeric(X(1).(FN{field}))
  SK=[X.(FN{field})]';
  [foo,I]=sort(SK,1,mode);
else
  if nargin==3
    disp('note: mode specification not supported for cell arrays; sort is ''ascend''')
  end
  SK=[{X.(FN{field})}];
  [foo,I]=sort(SK);
end

Y=X(I);
