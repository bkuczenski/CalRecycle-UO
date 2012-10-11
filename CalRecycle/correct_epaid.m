function [F,M]=correct_epaid(F,field)
% function F=correct_epaid(F,field)
%
% given a table 'F' and a key field 'field', create a list of valid EPAIDs through
% flookup and replace non-valid EPAIDs with valid ones using strdist2.
%
% function [F,M]=correct_epaid(F,field)
% provides a logical list of corrected EPAIDs.

disp(['Looking up spurious ' field 's'])
[~,IDM]=flookup(F,field,'FAC_NAME');
NM=rmfield(F(~IDM),fieldnames(rmfield(F,field)));
NM=mvfield(NM,field,['BAD_' field]);

disp(['Correcting spurious ' field 's with bestmatch valid IDs'])
NM=vlookup(NM,['BAD_' field],F(IDM),field,field,'strdist2');
nmbest={NM.(field)};
[F(~IDM).(field)]=deal(nmbest{:});
M=~IDM;
