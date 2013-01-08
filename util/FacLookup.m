function FacLookup(ID)
% function FacLookup(ID)
global Facilities
if iscell(ID)
  for k=1:length(ID)
    s(k)=FACILITY_lookup(ID{k});
  end
  show(Facilities(s))
else
  Facilities(FACILITY_lookup(ID))
end


