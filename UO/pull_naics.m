function B=pull_naics(N,field,codes)
% function B=pull_naics(N,field,codes)
% makes a naics tree using specified code masks.  All records not matched by a
% mask will be accumulated at the 2-digit level.

% first, keeps only relevant columns
FN=fieldnames(N);
NAICS=find(~cellfun(@isempty,strfind(FN,'NAICS')));
COUNT=find(~cellfun(@isempty,regexp(FN,'Count[0-9]*')));

N=select(N,[FN(NAICS)  FN(COUNT')  {field}]);

FN=fieldnames(N);
NAICS=find(~cellfun(@isempty,strfind(FN,'NAICS')));

[~,M]=filter(N,FN{NAICS},{@isempty},'');
[~,Mm]=filter(N,FN{NAICS},{@regexp},'^\s+$');
M=M|Mm;
[N(M).(FN{NAICS})]=deal('999999');

cols=repmat('m',1,length(FN));
cols(find(strcmp(FN,field)))='a';
cols(find(~cellfun(@isempty,regexp(FN,'Count[0-9]*'))))='a';

B=[];

for i=1:length(codes)
  [a,M]=filter(N,FN{NAICS},{@regexp},['\<' codes{i}]);
  if ~isempty(a)
    [a.(FN{NAICS})]=deal(codes{i});
    a=(accum(a,cols,''));
%    show(a)
    B=[B;a];
    N=N(~M);
  end
end
cols(NAICS)='2';
A=accum(N,cols,'');
A=mvfield(A,[FN{NAICS} '2'],FN{NAICS});
%keyboard
B=[B; A];
