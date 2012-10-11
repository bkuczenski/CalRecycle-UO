function R=cr_h_t_check(H,T)
% function R=cr_h_t_check(H,T)
%
% Takes CR_Hauler and CR_Txfr_DC and attempts to reconcile them:
%
% for each year, accumulates on EPAID and checks accumulated Txfrs for SrcEPAID
% against hauler, then DestEPAID against Hauler.  see what falls out.

years=2004:2010;

for i=6:length(years)
  myH=accum(filter(H,'Year',{@eq},years(i)),'dmdmddddddddddddddddadda','A');
  myTs=accum(filter(T,'Year',{@eq},years(i)),'mddmaaadd','A');
  myTd=accum(filter(T,'Year',{@eq},years(i)),'dmdmaaadd','A');
  
  myH=vlookup(myH,'EPAIDNumber',myTs,'SrcEPAID','ATotal','zero');
  myH=mvfield(myH,'ATotal','ATotalSrc');
  
  myH=vlookup(myH,'EPAIDNumber',myTd,'DestEPAID','ATotal','zero');
  myH=mvfield(myH,'ATotal','ATotalDest');
  
  a=[myH(:).ATotalSrc];
  b=[myH(:).ATotalTransferedGallons];

  g=myH(find(a-b));
  show(g)
%  disp(years(i))
%  show(myH(find(a-b)))

  tot=accum(myH,'ddaadaa','W');
  err=accum(myH(find(a-b)),'ddaadaa','X');
%  show(cell2struct(num2cell(cellfun(@rdivide,struct2cell(err),struct2cell(tot))), ...
%                   {'FracGal','FracTxfr','FracSrc','FracDest','FracRecords'}))
  
  R(i).NumRecords=length(find(a-b));
  R(i).TotalGal=tot.WAGrandTotalGallons;
  R(i).Implicated=err.XAGrandTotalGallons;
  R(i).Deficiency=tot.WATotalTransferedGallons-tot.WATotalSrc;
  R(i).DefFrac=R(i).Deficiency/R(i).TotalGal;
  R(i).Dest=err.XATotalDest;
end
show(R)

%%
%% results:
%% 2004: 1 record; 0.52% of collection
%% 2005: 1 record; 0.55% of collection
%% 2006: 7 records; 4.0% of collection
%% 2007: 9 records; 2.85% of collection
%% 2008: 2 records; 0.47% of collection
%% 2009: 9 records; 34.9% of collection
