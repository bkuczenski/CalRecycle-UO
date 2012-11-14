function DB=Query(DB,Row,Column,varargin)
% looks up column of data by row and column; returns a substructure
for i=1:DB.NumQuantities
  S(i)= subsref( DB.Data{i}, struct(...
      'type','()','subs',{{Row,Column}}));
end
DB.Rows=DB.Rows(Row,:);
DB.Cols=DB.Cols(Column,:);
DB=rmfield(DB,{'Data','NumRecords','NumRows','NumCols'});
DB.Result=S';
if nargout==0
  disp([DB.RowHeading{1} ': ' DB.Rows{1} '  ' DB.Rows{2} ])
  disp(['to ' DB.ColumnHeading{1} ': ' DB.Cols{1} '  ' DB.Cols{2} ])
  disp([ DB.Quantities num2cell(DB.Result) ])
end

  
