function E=fac_list(years,wcs)
% this function returns a listing of unique EPAID numbers that appear as either
% generators or TSDFs for the given waste code(s) in the given year(s).  Drops
% syntactically invalid EPAIDs.

E={};
tic;
for i=1:length(years)
  yy=num2str(years(i));
  fprintf('Year %s: ',yy);
  CR=load(['CR_' yy '.mat']);
  ee=unique({CR.(['CR_' yy]).Rin.EPAID});
  E=unique({E{:} ee{:}});
toc;
end

E=cell2struct(E,'GEN_EPA_ID');
