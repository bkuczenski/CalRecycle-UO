function [D,DID]=crquarteryear(D,fn)
% function D=crquarteryear(D)
% converts CalRecycle quarter-year ID field to Quarter and Year.  Replaces the one
% field with two (second field inserted in-place).
%
% function D=crquarteryear(D,fn)
% By default, uses fieldname 'QuarterYearID', but an alternative fieldname can be
% provided as an optional second argument.
%
% mapping from QuarterYearID to quarter: mod(*-3,4)={0,1,2,3} -> {Q1,Q2,Q3,Q4}
% mapping from QuarterYearID to year: 1874+floor((*-3)/4) = year
%
% Example: QuarterYearID=550 corresponds to Oct-Dec 2010
%

if nargin<2
  fn='QuarterYearID';
end

FN=fieldnames(D);

I=find(strcmp(FN,fn));
switch(fn)
  case 'QuarterYearID'
    D=moddata(D,fn,@(x)(1874+floor((x-3)/4)),'Year');
    D=moddata(D,fn,@(x)(['Q' num2str(1+mod(x-3,4))])); % replace field
  case 'QuarterYear'
    QYMap=struct('Str',{'Ja','Ap','Ju','Oc'},'Map',{'Q1','Q2','Q3','Q4'});
    D=moddata(D,'QuarterYear',@(x)(cell2mat(regexp(x,'[0-9]{4}','match'))),'Year');
    D=vlookup(moddata(D,fn,@(x)(subsref(x,substruct('()',{1:2})))),...
              fn,QYMap,'Str','Map','inplace');
  otherwise
    disp(['fn = ' fn '; I''m confused.'])
    keyboard
end
D=orderfields(D,[1:I, length(FN)+1, (I+1):length(FN)]);
D=mvfield(D,fn,'Quarter');

if nargout>1
  DID=accum(D,'ddmm'); % accum list of EPAIDs
  DID=orderfields(DID,[2 3 1]);
  DID=flookup(DID,'EPAIDNumber','FAC_NAME'); % crosscheck them against
                                             % facility master list
end
