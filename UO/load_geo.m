% script file to load the geographic context for the database work
% need mapping toolbox

global GEO_CONTEXT
global GEO_REGION
global UNIT_CONV

global Facilities  % data structure array
global FACILITIES  % cell array list of unique facility EPAIDs 

global MD
global Node
%global use_md2
%use_md2=true

load FacilitiesUO

GEO_CONTEXT='Facilities_UO'
GEO_REGION='^CA'

%% to add a new facility entry:
%% load Facilities
% Make a Facility structure F
% use bisect_find(NEW_KEY,FACILITIES) to determine the correct key location
% call it k
% store it: Facilities=[Facilities(1:k-1) F Facilities(k:end)];
%% This should be done in decreasing order so that the key location for
%% lower-ordered keys is not corrupted by an insertion
% FACILITIES={Facilities(:).GEN_EPA_ID}
% save Facilities FACILITIES Facilities
