function C=plus(A,B)
% fails if A and B have different fields
FN=fieldnames(A);

if ~all(isfield(B,FN))
  disp('Different fields!')
  L=false;
  return
end

for i=1:length(FN)
  C.(FN{i})=A.(FN{i})+B.(FN{i});
end