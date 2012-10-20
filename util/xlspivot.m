function xlspivot(xlsfile,D,name)
% function xlspivot(xlsfile,D)
% function xlspivot(xlsfile,D,name)
%
% Writes data structure D to a prebuilt XLS pivot table file.  The prebuilt file
% is assumed to have a worksheet named 'Extents' which is populated with the
% following structure: 
%
% |     |    A    |    B    |    C    | . . .
% +-----+---------+---------+---------+---
% |  1  |DataSheet|name     |         | . . .
% |  2  |NumRows  |###      |         | . . .
% |  3  |NumCols  |###      |         | . . .
% |  4  |         |         |         | . . .
%
% where 'name' is the name provided in the 3rd argument (default 'Data'); NumRows
% is length(D) and NumCols is length(fieldnames(D))

XLS_TEMPLATE='xlspivot_template.xls';

if nargin<3 name='Data'; end
if ~exist(xlsfile,'file')
  copyfile(which(XLS_TEMPLATE),xlsfile);
end


E=struct('DataSheet',name,'NumRows',length(D),'NumCols',length(fieldnames(D)));
xlswrite(xlsfile,struct2xls(E)','Extents');
xlswrite(xlsfile,struct2xls(D),name);
