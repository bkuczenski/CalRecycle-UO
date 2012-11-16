function [D,M]=flookup(D,KeyField,varargin)
% function [D,M]=flookup(D,KeyField,ReturnField)
% Performs a bisection search into the current global Facilities database
% to lookup EPAIDs.  Populates a new field with the contents of the named
% ReturnField from the Facilities database.  If ReturnField is omitted or
% empty, populates a field called 'FAC_INDEX' with the index into the
% facilities database.  No inexact matches are supported.
%
% The performance improvement is substantial.  For the following test, MDb 
% has 946 records and Facilities has 129,258 records.
% 
% >> tic;MDb=flookup(MDb,'GEN_EPA_ID','FAC_NAME');toc
%
% Elapsed time is 0.642782 seconds.
%
% >> MDb=rmfield(MDb,'FAC_NAME')
%
% MDb = 
%
% 946x1 struct array with fields:
%     GEN_EPA_ID
%     WASTE_STATE_CODE
%     METH_CODE
%     Accum__TONS
%     Count
%     FAC_OLDNAME
%     FAC_INDEX
%
% >> tic;MDb=vlookup(MDb,'GEN_EPA_ID',Facilities,'GEN_EPA_ID','FAC_NAME');toc
%
% Elapsed time is 15.699443 seconds.
%
% >> 
%
% The appropriate joke here is that I just spent 3 hours to save 15 seconds.
%
% 'inplace' as 4th arg works to replace the key field.

inplace=false;
blank=0;

if nargin==1
  if isfield(D,'EPAID')
    KeyField='EPAID';
  elseif isfield(D,'TSDF_EPA_ID')
    KeyField='TSDF_EPA_ID';
  elseif isfield(D,'GEN_EPA_ID')
    KeyField='GEN_EPA_ID';
  elseif isfield(D,'EPAIDNumber')
    KeyField='EPAIDNumber';
  else
    error('Cannot determine a good KeyField.')
  end
  ReturnField='FAC_NAME';
  inplace=true;
end

while ~isempty(varargin)
  if ischar(varargin{1})
    switch varargin{1}(1:3)
      case 'inp'
        inplace=1;
      case 'bla'
        blank=1;
      case 'zer'
        blank=2;
      otherwise
        ReturnField=varargin{1};
    end
  else
    disp('Don''t understand argument:')
    disp(varargin{1})
    keyboard
  end
  varargin(1)=[];
end

rtn_index=false;

global Facilities

if ~isfield(Facilities,ReturnField)
  rtn_index=true;
  DestField='FAC_INDEX';
else
  if inplace
    DestField=KeyField;
  else
    DestField=ReturnField;
  end
end

[~,M]=filter(D,KeyField,{@regexp},'^[A-Z]{2}[A-Z0-9][0-9]{9}$');

facmatch=cellfun(@FACILITY_lookup,{D(M).(KeyField)},'UniformOutput',0);

N=zeros(size(D));
N(M)=[facmatch{:}]; % N contains matching indices or 0 for nonmatching
if rtn_index
  RtnData=num2cell(N);
else
  RtnData=repmat({''},length(N),1);
  %  keyboard
  [RtnData{find(N)}]=Facilities(N(find(N))).(ReturnField);
  switch blank
    case 0
      [RtnData{find(N==0)}]=D(find(N==0)).(KeyField);
    case 2 % fill with zeros
      [RtnData{find(N==0)}]=deal(0);
  end % else leave blank
end
[D(:).(DestField)]=RtnData{:};
M=logical(zeros(size(D)));
M(find(N))=true;
