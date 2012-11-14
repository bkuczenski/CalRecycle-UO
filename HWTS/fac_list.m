function E=fac_list(years,wcs)
% this function returns a listing of unique EPAID numbers that appear as either
% generators or TSDFs for the given waste code(s) in the given year(s).  Drops
% syntactically invalid EPAIDs.

E={};
tic;
for i=1:length(years)
  yy=num2str(years(i));
  fprintf('Year %s: ',yy);
  for j=1:length(wcs)
    wc=num2str(wcs(j));
    fprintf('wc %s; ',wc);
    MD=load(['Tanner' yy '/MD_' yy '_' wc '.mat']);
    MG=filter(select(MD.(['MD_' yy '_' wc]),'GEN_EPA_ID'),...
              'GEN_EPA_ID',{@regexp},'^[A-Z]{2}[A-Z0-9][0-9]{9}$');
    MT=filter(select(MD.(['MD_' yy '_' wc]),'TSDF_EPA_ID'),...
              'TSDF_EPA_ID',{@regexp},'^[A-Z]{2}[A-Z0-9][0-9]{9}$');
    ee=unique({MT.TSDF_EPA_ID MG.GEN_EPA_ID});
    E=unique({E{:} ee{:}});
  toc;
end
end

E=cell2struct(E,'GEN_EPA_ID');
