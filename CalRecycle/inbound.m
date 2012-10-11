function inbound(ID,man)
% function F=inbound(ID,man)
% man = manifest table
% ID = EPAID
global Facilities

Facilities(FACILITY_lookup(ID))
fprintf('\n%s\n','Inbound From:')
t=sort(accum(filter(man,'TSDF_EPA_ID',{@strcmp},ID),'mddddda',''),2);
show(top(t,2,100))

if ~isempty(t)
  fprintf('\n%s\n','Inbound Disposition:')
  show(meth_lookup(sort(accum(filter(man,'TSDF_EPA_ID',{@strcmp},ID),'dddddma', ...
                              ''),2,'descend')))
end

disp(' ')
disp('Outbound to:')
show(sort(accum(filter(man,'GEN_EPA_ID',{@strcmp},ID),'ddmddma',''),3,'descend'))
