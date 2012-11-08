function D=moddata(D,Field,Fn,new)
% function D=moddata(D,Field,Fn)
% Perform an element-wise function on a column of data.  Field is either a field
% name or an index into fieldnames.  Fn is a handle to the function (could be
% anonymous).  
%
% function D=moddata(D,Field,Fn,new)
% If a fourth arg is present, add a new field with the name specified in 'new'
% containing the function output; leave the source column intact.

if nargin<4 new=''; end

if isnumeric(Field)
  FN=fieldnames(D);
  Field=FN{Field};
end

for i=1:length(D)
  mydat=feval(Fn,D(i).(Field));
  if isempty(new)
    D(i).(Field)=mydat;
  else
    D(i).(new)=mydat;
  end
end
