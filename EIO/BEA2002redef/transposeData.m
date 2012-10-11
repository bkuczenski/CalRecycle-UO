function IODataT=transposeData(IOData)
% switches row and column
IODataT=IOData;

IODataT.ColumnHeading = IOData.RowHeading;
IODataT.Cols = IOData.Rows;
IODataT.NumCols = IOData.NumRows;


IODataT.RowHeading = IOData.ColumnHeading;
IODataT.Rows = IOData.Cols;
IODataT.NumRows = IOData.NumCols;

if isfield(IOData,'Data')
  for i=1:IOData.NumQuantities
    IODataT.Data{i} =  IOData.Data{i}';
  end
end

