function T=transform(S,varargin)
% function T=transform(S,KeyField,DataField,X)
% 
% transforms the data in T (as input data) into a series of outputs defined by a
% transformation table X.  X looks like:
%
% KeyField Out1 Out2 Out3...
% keyval   x1   x2   x3...
% keyval..
%
% Entries in S.KeyField which don't match a keyval (or with empty xk) will wind up
% with zero entries.
%
% Returns a structure with fieldnames equal to the data fields for X, and values
% equal to the accumulated results over all inputs.
%
% function T=transform(S,DataField,X)
%
% with 3 arguments, assumes KeyField=1.

FN=fieldnames(S);

switch nargin
  case 4
    [KeyField,DataField,X]=deal(varargin{:});
  case 3
    [DataField,X]=deal(varargin{:});
    KeyField=FN{1};
  otherwise
    error('nargin')
end

if isnumeric(DataField)
  DataField=FN{DataField};
end

XN=fieldnames(X);
NumOut = length(XN)-1;

for i=1:NumOut
  S=vlookup(S,KeyField,X,XN{1},XN{i+1},'zero');
  prodx=num2cell([S(:).(DataField)] .* [S.(XN{i+1})]);
  [S(:).(XN{i+1})]=prodx{:};
end

for i=1:length(FN)
  if ~strcmp(FN{i},DataField)
    S=rmfield(S,FN{i});
  end
end

Td=num2cell(sum(transpose(cell2mat(struct2cell(S)))));
TN=fieldnames(S);

Td=[TN(:) Td(:)]';
T=struct(Td{:});

