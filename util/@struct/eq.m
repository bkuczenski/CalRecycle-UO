function L=eq(S1,S2)
% test if two structures are equal by testing if all their fields are equal.

FN=fieldnames(S1);

L=true;

if ~all(isfield(S2,FN))
  disp('Different fields!')
  L=false;
  return
end

for i=1:length(FN)
  if ~all([S1.(FN{i})]==[S2.(FN{i})])
    L=false;
    return
  end
end
