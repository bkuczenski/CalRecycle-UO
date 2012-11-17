function [Q,Ng] = uo_naics(Q,field)
% function [Q,Ng] = uo_naics(Q,field)

Q=rmfield(Q,{'GEN_CNTY','TSDF_CNTY'});

Ts=unique({Q.TSDF_EPA_ID});
[~,istx]=filter(Q,'GEN_EPA_ID',{@ismember},{Ts});

Q=flookup(Q(~istx),'GEN_EPA_ID','NAICS_CODE','bla');
Q=mvfield(Q,'NAICS_CODE','GEN_NAICS');
Q=select(Q,{'GEN_EPA_ID','GEN_NAICS','TSDF_EPA_ID','WASTE_STATE_CODE','WC','METH_CODE','GAL'})

Ng=expand(Q,'GEN_NAICS',' ',field);
Ng=moddata(Ng,'GAL',@floor);
Ng=accum(Ng,'dmdmda','');
