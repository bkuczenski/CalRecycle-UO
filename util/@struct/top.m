function [Dt,M]=top(D,field,n,Cols)
% function Dt=trunc(D,field,n,Cols) Sorts data structure by the given field (assumed
% numeric) and displays the top n records.  Truncates and aggregates all records
% below the supplied threshold.
%
% Cols should be an accum-friendly column spec containing only 'd's and 'a's

FND=fieldnames(D);
if isnumeric(field)
  field=FND{field};
end

if n>=length(D)+1 % +1 for "all remaining"
  mythresh=0;
else
  Dt=sort(D,field,'descend');
  mythresh=mean([Dt([n:n+1]).(field)]);
end
if nargin<4 Cols=''; end
[Dt,M]=trunc(D,field,mythresh,Cols);

