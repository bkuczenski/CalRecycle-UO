function S=ifrmfield(S,F)
% remove field if it exists.  geez mathworks, some UI stuff is bone simple.
if ~iscell(F)
  F={F};
end
for i=1:length(F)
  if isfield(S,F{i})
    S=rmfield(S,F{i});
  end
end
