function S=query_tex_dat(D,fname,annot,query,meta)
% function S=query_tex_dat(D,fname,annot,query)
%
% D is data source- flattened structure
% fname is the arrayname and the file to write '-working.dat'
% annot is a list of annotations: titles, style selections, etc "meta" columns 
% query is a list of TeXKeys to query
% 
% outputs a file to be read into TeX in an arraydata file
%
% Returns a structure containing the data written.
%
% function S=query_tex_dat(D,fname,annot,query,meta)
% 
% provides a fieldname to indicate the presence of metadata.  Entries in ths field
% beginning with '*' are interpreted as metadata fields; the characters after the
% star are used as printf format specifiers to print the data.

prefix=annot{1};
commonkey='TeXKey';
firstdatacol='A';

FN={commonkey,annot{2:end}};

if iscell(query)
  S=cell2struct(query,FN,2);
else
  S=query;
end

myfield=double(firstdatacol);

for i=1:length(D)
  S=vlookup(S,commonkey,D{i},commonkey,'Value','zero');
  S=mvfield(S,'Value',[prefix char(myfield+i-1)]);
end

if isempty(fname)
  % skip writing to file
else
  filename=[fname '-working.dat'];
  % write meta and data differently- but how to detect? 
  show(S,'',filename);
end
