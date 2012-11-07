function id=FACILITY_lookup(EPAID,varargin)
% function id=FACILITY_lookup(EPAID)
%
% access facilities list to determine whether an EPAID is represented.
% ultimately this should be a private rather than global method.  
% FACILITIES is the sorted list of EPAIDs found in the current Facilities.mat 
% address matrix, in cell array form.  This is faster than the alternative.
%
% Optional arguments can do stuff.

id=false;
global FACILITIES
if isempty(FACILITIES)
  disp('No FACILITIES database.')
  return
end

pad=char({EPAID;FACILITIES{1}});
EPAID=pad(1,:);

try 
  t_id=bisect_find(EPAID,FACILITIES);
catch
  disp(EPAID)
  keyboard
end
if FACILITIES{t_id}==EPAID % only assign output if exact match is found
  id=t_id;
end


