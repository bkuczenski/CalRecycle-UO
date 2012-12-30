function B=build_naics(N,field,par)
% function B=build_naics(N,field,par)
%
% constructs a NAICS tree via attrition-and-aggregation
if nargin<3 par=0.08; end

upper_lvl=1;

agg=sum([N.(field)]);
thresh=agg*par;

FN=fieldnames(N);
NAICS=find(~cellfun(@isempty,strfind(FN,'NAICS')));

[~,M]=filter(N,FN{NAICS},{@isempty},'');
[~,Mm]=filter(N,FN{NAICS},{@regexp},'^\s+$');
M=M|Mm;
[N(M).(FN{NAICS})]=deal('999999');

cols=repmat('m',1,length(FN));
cols(find(strcmp(FN,field)))='a';
cols(find(~cellfun(@isempty,regexp(FN,'Count[0-9]*'))))='a';

b=top(N,field,1);
lvl=length(b(1).(FN{NAICS}));

B=[];

while lvl>upper_lvl
  fprintf('%s %d\n','curr level',lvl);
  if b(1).(field) >thresh
    B=[B;b(1)];
    N=filter(N,FN{NAICS},{@strcmp},b(1).(FN{NAICS}),1);
    b=top(N,field,1);
  else
    fprintf('NAICS %s b(1).%s: %f thresh: %f\n',b(1).(FN{NAICS}),field,b(1).(field),thresh)
    lvl=lvl-1;
    cols(NAICS)=num2str(lvl);
    N=accum(N,cols,'');
    N=mvfield(N,[FN{NAICS} num2str(lvl)],FN{NAICS});
    N=select(N,FN);
    b=top(N,field,1);
  end
  if length(N)==0 
    break
  end
end
%keyboard
B=[B;N];
[~,M]=filter(B,FN{NAICS},{@regexp},'^9+$');
[B(M).(FN{NAICS})]=deal('unknown');
cols(NAICS)='m';
B=accum(B,cols,'');
B=select(B,FN);
B=sort(B,field);
