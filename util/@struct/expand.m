function S=expand(S,EF,delim,DF)
% function S=expand(S,expandfield,delim,datafield)
%
% Splits records in S in cases when expandfield contains delimited entries.  In
% effect, inverts an accum function with concatenation.
% 
% For each record, checks to see if expandfield contains multiple entries
% separated by delimeter delim.  If it does, the function duplicates the record so
% that there is one record for each delimited entry.  Each field named in
% datafield is partitioned equally over all records.  datafield can be a cell
% array of fields, in which case each field is partitioned independently.

transp=false;

if nargin<3   DF={}; end
if ~iscell(DF) DF={DF}; end
if size(S,2)<size(S,1)
  S=S';
  transp=true;
end

for i=length(S):-1:1
  % since we're adding records, we go backwards
  parts=regexp(S(i).(EF),delim,'split');
  parts(cellfun(@isempty,parts))=[];

  L=length(parts);
  if L>1
    Ssub=S(i);
    for j=1:length(DF)
      Ssub.(DF{j})=Ssub.(DF{j})/L;
    end
    Ssub=repmat(Ssub,1,L);
    [Ssub.(EF)]=parts{:};
    S=[S(1:i-1) Ssub S(i+1:end)];
  end
end

if transp S=S'; end
