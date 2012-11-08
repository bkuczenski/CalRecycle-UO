function [F,Mf]=correct_epaid(F,field,upd)
% function F=correct_epaid(F,field)
%
% given a table 'F' and a key field 'field', create a list of valid EPAIDs through
% flookup and replace non-valid EPAIDs with valid ones using strdist2.  F should
% be of minimal length (i.e. each EPAID should appear only once).
%
% function [F,M]=correct_epaid(F,field)
% provides a logical list of corrected EPAIDs.
%
% correct_epaid(F,field,update)
% if a third argument is present, detected changes will be appended to EPAID.Corr

% first things first: read established corrections from EPAID.Corr
CORRFILE='EPAID.Corr';

disp('Applying manual corrections:')
EC=read_dat(CORRFILE,',');
[F,Mf]=vlookup(F,field,EC,'IN','OUT','inplace');

fprintf(1,'%d records corrected.',sum(Mf));

disp(['Identifying spurious ' field 's'])
E=unique({F.(field)});
[~,M]=flookup(cell2struct(E,'EPAID'),'EPAID','GEN_EPA_ID','bla');

if sum(~M)>0
  fprintf(1,'%d bad %ss located.   Attempting to correct...\n',sum(~M),field);
  
  [Ek,Mk]=vlookup(cell2struct(E(~M),'EPAID'),'EPAID',...
                  cell2struct(E(M),'VALID_EPAID'),'VALID_EPAID','VALID_EPAID', ...
                  'strdist2');

  % Ek(Mk) contains newly identified corrections
  if sum(Mk)>0
    
    fprintf(1,'Applying %d discovered corrections:\n',sum(Mk))
    [F,Mff]=vlookup(F,field,Ek(Mk),'EPAID','VALID_EPAID','inplace');
    fprintf(1,'%d records corrected.\n',sum(Mff));
    %Fk=vlookup(F(~M),field,Ek(Mk),'EPAID','VALID_EPAID','inplace');
    
    Mf=[Mf|Mff];
    if nargin==3
      fprintf(1,'Writing %d discovered corrections to %s...\n',sum(Mk),CORRFILE);
      MYwd=pwd;
      %% need to deal with platform-dependent paths
      fwslash=length(strfind(pwd,'/'));
      bkslash=length(strfind(pwd,'\'));
      if bkslash>fwslash
        CORRwd=regexprep(which(CORRFILE),['\' CORRFILE],'');
      else
        CORRwd=regexprep(which(CORRFILE),['/' CORRFILE],'');
      end
      if ~strcmp(CORRwd,MYwd)
        cd(CORRwd)
      end
      show(Ek(Mk),'',{CORRFILE,3},',*');
      cd(MYwd)
    end
  else
    disp('No further corrections found.')
  end
else
  disp('No spurious EPAIDs found.')
end




%disp(['Looking up spurious ' field 's'])
%[~,IDM]=flookup(F,field,'FAC_NAME');
%NM=rmfield(F(~IDM),fieldnames(rmfield(F(1),field)));
%NM=mvfield(NM,field,['BAD_' field]);
%
%disp(['Correcting spurious ' field 's with bestmatch valid IDs'])
%NM=vlookup(NM,['BAD_' field],F(IDM),field,field,'strdist2');
%nmbest={NM.(field)};
%[F(~IDM).(field)]=deal(nmbest{:});
%M=~IDM;

  