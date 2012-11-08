function An=uo_activity(Rn,D,FacData)
% function An=uo_activity(Rn,D,FacData)
% 
% looks up into a specially-designed table that matches inflows into a node to
% unit processes.
%
% Rn is an output of uo_node or similar
%
% D is a regexp of column headings that should be interpreted as disposition
% routes (method codes)
%
% FacData should contain the fields:
%  FACILITY_ID - regexp matching facilities
%  METH_CODE   - regexp matching method codes
%  FATE        - disposition process name
%  FRACTION    - fraction to the named process
%  REMAINDER_TO- valid method code to recurse (max 3 recursions performed) 
%
%  KEY         - useful for debugging
%
% for multiple matches, the highest-index match is accepted.
% 
% FacData functions as a mapping from facility name + method code to fate, where each
% fate names a unit process inventory.  The activity level of the resulting named
% unit process inventory measures the amount of mass delivered to it.
%
% n.b.: The function uses rexegp, a version of regexp in which the order of input
% arguments has been reversed.

debug=false;

An=select(Rn,'TSDF_EPA_ID');
As=unique({FacData.FATE});
Aq=zeros(length(An),length(As));

FacData=moddata(FacData,'FATE',@(x)(find(strcmp(As,x))),'fi');

FN=fieldnames(Rn);
Ds=FN(~cellfun(@isempty,regexp(FN,D))); % fieldnames matching D

Rn=struct2cell(select(Rn(:),Ds));

for i=1:length(An)
  if debug fprintf('debug:: Facility: %s \n',An(i).TSDF_EPA_ID); end
  F=filter(FacData,'FACILITY_ID',{@rexegp},An(i).TSDF_EPA_ID);
  in=[Rn{:,i}];
  findin=find(in);
  for j=1:length(findin)
    if debug fprintf('  Qty: %10.2f',in(findin(j))); end
    Aq(i,:)=Aq(i,:)+in(findin(j))*lookup_meth_code(As,F,Ds{findin(j)},debug); 
  end
end

An=union(An,cell2struct(num2cell(Aq'),As));


function Ani=lookup_meth_code(As,F,Meth,debug)
% recursive lookup into methcode-fate
[~,M]=filter(F,'METH_CODE',{@rexegp},Meth);
ind=max(find(M));
if debug 
  fprintf('%6s: %d  Meth: %s -> Fate: %s\n','KEY',F(ind).KEY,Meth,F(ind).FATE);
end
      
if F(ind).FRACTION<1
  if debug fprintf('%10s %1.4f','R',1-F(ind).FRACTION); end
  Ani=(1-F(ind).FRACTION)*lookup_meth_code(As,F,F(ind).REMAINDER_TO,debug);
else
  Ani=zeros(size(As));
end
k=find(strcmp(As,F(ind).FATE));
Ani(k)=Ani(k)+F(ind).FRACTION;
