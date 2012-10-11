function T=top_tsdfs(year,wc,thresh)
% function T=top_tsdfs(year,wc,thresh)
% shows top Processing facilities from md_node2 output as intermediate
% interpretive aid.  Default wc (if omitted) is 221.  Default thresh is 2e-4*total


if nargin<2
  wc=221;
end

varname=['Tn_' num2str(year) '_' num2str(wc)];

S=load(['MD-Tn2_' num2str(year) '_' num2str(wc)]);


if nargin<3
%  keyboard
  q=getfield(accum(select(S.(varname),'H039'),'a',''),'H039');
  thresh=q/5000;
end


T=flookup(S.(varname),'TSDF_EPA_ID','FAC_NAME');
n=length(fieldnames(T));
try
  
  T=select(T,[1 2 3 4 5 6 8 10 n 11:n-2]);
catch
  keyboard
end
show(trunc(T,'H039',thresh))
show(select(trunc(T,'H039',thresh),{'DispGAL','TSDF_EPA_ID','FAC_NAME'}))
