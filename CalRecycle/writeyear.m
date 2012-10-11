function S=writeyear(year)
% function S=writeyear(year)
% still struggling with the best way to pull this off.  I think: a data extraction
% should be a script file, but data conditioning should be a function because
% there are multiple years.  The script should call the functions to the degree
% needed.  The output to TeX should be as generic as possible.  
%
% So: what needs to get output to TeX?  
%  (1) a data file .dat, &-delimited, including correct SetSource / NumRows
%  specifications;
%  (2) template code to draw a bar.  this could either be done in matlab or by
%  hand, but I do want to move to a point where bar-drawing is a think-free job.

load CRData
D=mfa_extract(CRData,year);


% what do we want to print?
% ref, var, label, style
tab_cols={'Value','Key','Label','Style'};

for i=1:size(tab_rows,2)
  tab_rows{1,i}=tryassign(D,tab_rows(:,i));
end

S=cell2struct(tab_rows,tab_cols);

function val=tryassign(D,row);
try
  val=eval(['D.' row{1}]);
catch
  val=0;
end