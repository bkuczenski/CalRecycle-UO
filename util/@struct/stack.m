function S=stack(S1,S2)
% function S=stack(S1,S2)
% prelude to vertcat
%
% creates a new structure whose fields are the union of the two input structures,
% padded with zero if numeric, '' if string.

if isempty(S1)
  S=S2;
  return
elseif isempty(S2)
  S=S1;
  return
end

FNS1=fieldnames(S1);
FNS2=fieldnames(S2);
allFN=union(FNS1,FNS2);
d1=setdiff(allFN,FNS1);
d2=setdiff(allFN,FNS2);

for i=1:length(d1)
  if isnumeric(S2(1).(d1{i}))
    [S1.(d1{i})]=deal(0);
  else
    [S1.(d1{i})]=deal('');
  end
end
for i=1:length(d2)
  if isnumeric(S1(1).(d2{i}))
    [S2.(d2{i})]=deal(0);
  else
    [S2.(d2{i})]=deal('');
  end
end

sortorder=[FNS1;d1];

S1=S1(:);
S2=S2(:);

S=orderfields(S1,sortorder);
S=[S ; orderfields(S2,sortorder)];

    

%function c=fne(S,F)
%% first nonempty entry of field F in struct S
%C={S.(F)};
