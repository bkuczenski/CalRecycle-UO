function S=Facility_search(str,arg)
% function S=Facility_search(str)
% searches through the global Facilities database for the given string (regexp).  
%
% function S=Facility_search(str,field)
% by default, searches on FAC_NAME; but an optional second argument will perform
% the search on a different field (say, FAC_CITY)

if nargin<2
  arg='FAC_NAME';
end

global Facilities
S=filter(Facilities,arg,{@regexpi},str);
