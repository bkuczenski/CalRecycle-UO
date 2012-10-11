function a=aggregateData(DB,matchRows,matchCols)
% function a=aggregateData(DB,match)
% 
% Aggregates data stored in DB according to a hierarchical specification in
% 'match'.  If 'match' is a number, it is interpreted as a number of digits for
% the aggregation (e.g. match=1 would aggregate NAICS codes along 100000, 200000,
% 300000,... )
%
% If 'match' is a string, it aggregates all rows that match that string
% (e.g. '325' would return all chemical manufacturing entries aggregated.)
%
% function a=aggregateData(DB,matchRows,matchCols)
% will apply different matching rules to rows and columns.  '' means no
% aggregation.


a=DB;

if nargin<2   matchRows=3; end % default: subsector-level aggregation
if nargin<3   matchCols=matchRows; end

if ischar(matchRows)
  RBins={matchRows}
elseif iscell(matchRows)
  
else

end

