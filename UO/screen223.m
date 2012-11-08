function [Qk,Qx]=screen223(Q,DROP)
% function Q=screen223(Q,DROP)
% Special function for screening out non-used-oil from inbound WC 223.  Assumes
% certain container types inherently have no recoverable used oil; those records
% are removed.
%
% function [Q,Qx]=screen223(Q,DROP) will report dropped records in the
% complementary structure Qx.
%
% Default DROP list is {'BA','CF','CM','CW','DT','DW','HG'} if no second argument
% is supplied.

% get rid of NANs
[Q(find(isnan([Q.QUANTITY]))).QUANTITY]=deal(0);

global UNIT_CONV

if nargin<2
  DROP={'BA','CF','CM','CW','DT','DW','HG'};
end

disp('Filtering on container type (slow process...)')

% should use ismember instead
[Qk,M] = filter(Q,{'CONTAINER_TYPE'},{@ismember},{DROP},1);
Qx=Q(~M(:,end));


% do unit conversion-- into GAL
Qk=vlookup(Qk,'UNITS',UNIT_CONV,'UNIT','G','zer');
Qk=fieldop(Qk,'GAL','floor(#QUANTITY .* #G)');
Qk=mvfield(Qk,'CAT_CODE','WASTE_STATE_CODE');
Qk=select(Qk,{'GEN_EPA_ID','GEN_CNTY','TSDF_EPA_ID','TSDF_CNTY','WASTE_STATE_CODE','METH_CODE','GAL','CONTAINER_TYPE'});

