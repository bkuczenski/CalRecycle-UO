function [Dt,M]=trunc(D,field,thresh,Cols)
% function Dt=trunc(D,field,thresh,Cols)
% Sorts data structure by the given field (assumed numeric) and truncates and
% aggregates all records below the supplied threshold.
%
% Cols should be an accum-friendly column spec containing only 'd's and 'a's

FND=fieldnames(D);
if nargin<4 | isempty(Cols)
  % need to autodetect columns
  Cols='';
  for i=1:length(FND)
    k=1;
    while isempty(D(k).(FND{i})) & k<length(D) & k<100
      k=k+1;
    end
    firstlook=D(k).(FND{i});
    if isnumeric(firstlook)
      Cols=[Cols 'a'];
    else
      Cols=[Cols 'd'];
    end
  end
end

if isnumeric(field)
  field=FND{field};
end

Dt=sort(D,field,'descend');
[D_trail,M]=filter(D,field,{@lt},thresh);
if sum(M)>0
  % truncation to do
  A=accum(D_trail,Cols);
  
  Dt=Dt(1:sum(~M)+1);
  FNA=fieldnames(A);
  Cols=[Cols repmat('d',1,length(FND))];
  a_cnt=0;done_remaining=0;
  for i=1:length(FND)
    if Cols(i)=='a'
      a_cnt=a_cnt+1;
      Dt(end).(FND{i})=A.(FNA{a_cnt});
    else
      if done_remaining
        Dt(end).(FND{i})='';
      else
        Dt(end).(FND{i})='all remaining';
        done_remaining=1;
      end
    end
  end
end


