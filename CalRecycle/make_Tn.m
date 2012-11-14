function [T,Ti]=make_Tn(year,mc,wc)
% function T=make_Tn(year,mc)
%
% loads Tn for all 3 waste codes for a year, stacks them, and does cleanup.
% if second argument is specified, interpreted as a list of method codes to
% include, with all non-included codes going to "OtherUnknown". If mc is omitted
% or empty, reports all method codes.
%
% function T=make_Tn(year,mc,wc) uses only the waste code specified.
%
% function [T,Ti]=make_Tn(year,...)
% Ti is a cell array containing structures for the 3 waste codes individually.

yy=num2str(year);
global use_md2

if use_md2
  md_prefix='MD-Tn2_';
else
  md_prefix='MD-Tn_';
end

T=[];

if nargin==3
  if any(wc>220)
    wc=wc-220;
  end
else
  wc=1:3;
end

for i=wc
  if exist([md_prefix yy '_22' num2str(i) '.mat'])~=2
    md_node2(year,220+i,'force');
  end
  L=load([md_prefix yy '_22' num2str(i)]);
  Ti{i}=L.(['Tn_' yy '_22' num2str(i)]);
  if nargin>1 & ~isempty(mc)
    FN=fieldnames(Ti{i});
    disps=regexp(FN,'^[A-Z][0-9]+$','once','start');
    disps(cellfun(@isempty,disps))=deal({0});
    disps=logical(cell2mat(disps));
    kill=setdiff(FN(disps),mc);
    if ~isfield(Ti{i},'OtherUnknown')
      [Ti{i}.OtherUnknown]=deal(0);
    end
    for j=1:length(kill)
      Ti{i}=fieldop(Ti{i},'OtherUnknown',['#OtherUnknown + #' kill{j}]);
      Ti{i}=rmfield(Ti{i},kill{j});
    end
    gen=setdiff(mc,FN);
    for j=1:length(gen)
      [Ti{i}.(gen{j})]=deal(0);
    end
  end
  if isfield(Ti{i},'Others')
    Ti{i}=rmfield(Ti{i},'Others');
  end
end
Ti(cellfun(@isempty,Ti))=[];
if length(Ti)>1
  T=stack(Ti{1},Ti{2});
else
  T=Ti{1};
end
if length(Ti)>2
  T=stack(T,Ti{3});
end



