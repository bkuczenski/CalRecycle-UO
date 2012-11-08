function S=select(D,fields)
% function S=select(D,fields)
% 
% create a substructure from structure array D by selecting fields by name.
% fields should be a cell array of strings or an index into fieldnames.
% Nonexistent fields produce a message but no error.

FN=fieldnames(D);
k=logical(zeros(size(FN)));
if ischar(fields)
  fields={fields};
end

if iscell(fields)
  % assume cell array of field names
  for i=1:length(fields)
    k(find(strcmp(FN,fields{i})))=true;
  end
else
  k(fields)=true;
  fields=FN(fields);
end
S=rmfield(D,FN(~k));
O=[];FN=fieldnames(S);
for i=1:length(fields)
  O=[O find(strcmp(fields{i},FN))];
end
S=orderfields(S,O);

