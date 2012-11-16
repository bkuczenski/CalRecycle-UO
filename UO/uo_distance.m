function Q=uo_distance(Q,r)
% function Q=uo_distance(Q)
%
% Uses LAT_LONG in the Facilities data structure to estimate freight transport.
% Computes great circle distance between the two points using the haversine
% formula.   Returns a manifest record with LAT_LONG as the facility metadata and
% an additional data field containing the distance in km.  
%
% function Q=uo_distance(Q,r)
%
% Uses the supplied value of 'r' for the Earth's radius (default 6371 km).  If a
% different value of r is supplied, the distance measurement will be reported in
% units corresponding to the dimension of r.

if nargin<2
  r=6371; %km
end

fprintf(1,'Looking up %s Coords...\n','GEN_EPA_ID')
Q=mvfield(Q,'GEN_CNTY','LAT_LONG');
Q=flookup(Q,'GEN_EPA_ID','LAT_LONG','zer');
Q=mvfield(Q,'LAT_LONG','GEN_LATLONG');

fprintf(1,'Looking up %s Coords...\n','TSDF_EPA_ID')
Q=mvfield(Q,'TSDF_CNTY','LAT_LONG');
Q=flookup(Q,'TSDF_EPA_ID','LAT_LONG','zer');
Q=mvfield(Q,'LAT_LONG','TSDF_LATLONG');

d = {r * gc_distance({Q.GEN_LATLONG},{Q.TSDF_LATLONG})};
[Q.DISTANCE]=d{:};

function D = gc_distance(LL1,LL2)
% computes great circle distance using haversine formula.  
LL1(find(cellfun(@prod,LL1)==0))={[NaN NaN]};
LL2(find(cellfun(@prod,LL2)==0))={[NaN NaN]};
LL1=cell2mat(LL1');
LL2=cell2mat(LL2');
LAT1=LL1(:,1);
LONG1=LL1(:,2);
LAT2=LL2(:,1);
LONG2=LL2(:,2);

D = 2 * asin(sqrt( sind( (LAT2-LAT1)/2).^2 ...
                    + cosd(LAT1).*cosd(LAT2).*sind( (LONG2-LONG1)/2 ).^2));
