function [FF,MF]=fac_rec(EPAID,year)
% function F=fac_rec(EPAID,year)
% loads MD-Tn2 for all 3 waste codes and displays together

use=[1 2 3];

for i=3:-1:1
  L=load(['MD-Tn2_' num2str(year) '_22' num2str(i)]);
  T{i}=L.(['Tn_' num2str(year) '_22' num2str(i)])(...
      find(strcmp({L.(['Tn_' num2str(year) '_22' num2str(i)]).TSDF_EPA_ID},EPAID)));
  %keyboard
  if isempty(T{i})
    use(i)=[];
  else
    disps=regexp(fieldnames(T{i}),'^H[0-9]','once','start');
    disps(cellfun(@isempty,disps))=deal({0});
    disps=cell2mat(disps);
    ndisps=~logical(disps);
    disps(subsref(find(disps),substruct('()',{...
        find(cell2mat(struct2cell(select(T{i},find(disps))))==0)})))...
        =deal(0); % this is the awesomest line of code I've ever written
    T{i}=select(T{i},find(disps|ndisps));
    FN{i}=fieldnames(T{i});
  end
end

allFN={'TSDF_EPA_ID';'WASTE_STATE_CODE'};

for i=1:length(use)
  allFN=union(allFN,FN{use(i)});
end
allFN(strcmp(allFN,'Others'))=[];

for i=1:length(use)
  myadd=setdiff(allFN,FN{use(i)});
  for j=1:length(myadd)
    [T{use(i)}(1).(myadd{j})]=deal(0);
  end
  Tn{use(i)}=select(T{use(i)},allFN);
end

% now reorder the fields
disps=regexp(allFN,'^H[0-9]','once','start');
disps(cellfun(@isempty,disps))=deal({0});
%keyboard
for i=1:length(use)
  Tn{use(i)}=select(Tn{use(i)},[find(strcmp(allFN,'TSDF_EPA_ID')),
                      find(strcmp(allFN,'Year')),
                      find(strcmp(allFN,'WASTE_STATE_CODE')),
                      find(strcmp(allFN,'GenGAL')),
                      find(strcmp(allFN,'Import')),
                      find(strcmp(allFN,'DispGAL')),
                      find(strcmp(allFN,'TxIn')),
                      find(strcmp(allFN,'TxOut')),
                      find(strcmp(allFN,'TxLosses')),
                      find(strcmp(allFN,'Class')),
                      find(cell2mat(disps))]);
end

F=[];
for i=1:length(use)
  F=[F, Tn{use(i)}(find(strcmp({Tn{use(i)}.TSDF_EPA_ID},EPAID)))];
end

if nargout==0
  show(F)
else
  FF=F;
  MF=T;
end
