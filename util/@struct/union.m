function D=union(D,Dnew)
% function D=union(D,Dnew)
% Creates a structure whose fields are the union of the fields of the two input
% structures.   In cases where the two structures have the same field name but
% different contents, currently bails out to user intervention.
%
% Note: This is NOT A JOIN function! No lookup is performed.

FNA=fieldnames(D);
FNB=fieldnames(Dnew);

new=setdiff(FNB,FNA);
dup=intersect(FNA,FNB);

for i=1:length(dup)
  if ~(D.(dup{i})==Dnew.(dup{i}))
    fprintf('Disagreement between structures on field %s; \n',dup{i})
    fprintf('Assign to ''KEEP'' the value to preserve in the unified structure.\n')
    fprintf('Leave ''KEEP'' unassigned to use value from first arg.\n')
    clear KEEP
    keyboard
    if exist('KEEP','var')
      D.(dup{i})=KEEP;
    end
  end
end
for j=1:length(new)
  [D(1:end).(new{j})]=Dnew.(new{j});
end

    
