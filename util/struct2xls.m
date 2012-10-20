function C=struct2xls(S)
% function C=struct2xls(S)
% converts a structure array S into a cell array for easy write to xls.
C=[fieldnames(S) struct2cell(S(:))]';
