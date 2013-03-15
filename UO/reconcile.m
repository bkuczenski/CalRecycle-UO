function E=reconcile(fac,year)
% function E=reconcile(fac,year)
% reconciles a TSDF facility (given by EPAID) between CalRecycle and MD.
% if no year arg is supplied, uses 2007:2011

if nargin<2
  year=2007:2011;
end

global Node MD

WCs=221:223;

for i=1:length(year)
  yy=num2str(year(i));
  E(i).Year=year(i);
  for j=1:length(WCs)
    wc=num2str(WCs(j));
    nodename=['Rn_' yy '_' wc];
    k=find(strcmp({Node.(nodename).TSDF_EPA_ID},fac));
    if isempty(k)
      fprintf('Facility %s not found for yy=%s wc=%s\n',fac,yy,wc)
    else
      if j==1
        E(i).CR_total=Node.(nodename)(k).CR_GAL;
        E(i).CR_ind=Node.(nodename)(k).CR_indGAL;
        E(i).CR_out=Node.(nodename)(k).CR_prodGAL;
      end
      E(i).(['MD' wc '_DGAL'])=Node.(nodename)(k).DGAL;
      E(i).(['MD' wc '_H900'])=Node.(nodename)(k).H900GAL;
    end
  end
end
