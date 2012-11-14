function IOData=readIOData(IOData,filename);
% function IOData=readIOData(IOData);
% uses IOData.filename to determine which file to read
% reads row:
%  commodity type; industry of use; last field is year; data is fields 5 to n-1
%
% function IOData=readIOData(IOData,filename);
% reads data from filename, overwriting any existing filename field.



% function IOData=readIOData(IOData,T) where T is nonzero
% transposes industry and commodity
% 
% n.b.: Use table is prime reference, lists commodity (row) by industry (column);
% make table is industry by commodity.  
%
% make of commodity by industry means: industry makes the following commodities.
% use of commodity by industry means: commodity is used by the following
% industries.
%
% but commodity is the 'row' bc it represents flows; industry represents
% processes.
if nargin>1
  IOData.filename=filename;
end



fid=fopen(IOData.filename);

Names=strread(fgetl(fid),'%s'); % assumes table headings have no spaces
% now read in the data into a 3d array

% this file reads data: therefore this file should have priority in setting
% Quantities and NumQuantities
IOData.Quantities=Names(5:end-1);
IOData.NumQuantities=length(IOData.Quantities);
IOData.Quantities


Data=zeros(IOData.NumRows,IOData.NumCols,IOData.NumQuantities);
tic
for i=1:IOData.NumRecords
  f=fgetl(fid);
  if f==-1
    IOData.NumRecords=i-1;
    break
  else
    toks=strread(f,'%s');
  end
  
  DataVec=toks(end-IOData.NumQuantities:end-1);
    Commodity=lookup(IOData.Rows(:,1), toks{1});
    if isempty(Commodity)
      D{1}=toks{1};
      D{2}=grabname(toks(2:end));
      IOData.Rows=[IOData.Rows;D];
      Commodity=size(IOData.Rows,1);
      disp([' Adding Row Entry: ' D{1} ' ' D{2} ]);
    end
    nwc=numwords(IOData.Rows{Commodity,2});

    Industry=lookup(...
        IOData.Cols(:,1), ...
        toks{ 1 + nwc + 1 });
    if isempty(Industry)
      D{1}=toks{1 + nwc + 1 };
      D{2}=grabname(toks(1 + nwc + 2:end));
      IOData.Cols=[IOData.Cols;D];
      Industry=size(IOData.Cols,1);
      disp([' Adding Col Entry: ' D{1} ' ' D{2} ]);
    end

    Data(Commodity,Industry,:)=str2double(DataVec);

  if mod(i,2000)==0 disp(['Count = ' num2str(i) ...
          '; Commodity = ' num2str(Commodity) ...
          '; Industry = ' num2str(Industry) ...
          ]); toc;tic;end
                   
  
    
end
disp(['Count = ' num2str(i) ...
          '; Commodity = ' num2str(Commodity) ...
          '; Industry = ' num2str(Industry) ...
          ]);toc

for n=1:IOData.NumQuantities
  st=sparse(Data(:,:,n));
  if nnz(st)/prod(size(Data(:,:,n))) < 0.2
    CData{n}=st
  else 
    CData{n}=Data(:,:,n);
  end
end
IOData.Data=CData;


  

% end -----------------------------------------------------------------

function n=numwords(str)
n=numel(regexp(str,'\S+'));

