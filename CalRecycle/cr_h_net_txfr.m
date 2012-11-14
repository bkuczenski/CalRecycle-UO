function HH=cr_h_net_txfr(H,year)
% function H=cr_h_net_txfr(H,year)
% Computes the net oil received by each EPAID for a given year. assumes fields: 
%
% Quarter
% Year
% FacilityName
% EPAIDNumber
% LubCollectionStationsGallons
% LubIndustrialGallons
% LubMarineGallons
% LubAgriculturalGallons
% LubGovernmentGallons
% LubOutOfStateGallons
% LubOtherHaulersGallons
% LubTotalGallons
% IndCollectionStationsGallons
% IndIndustrialGallons
% IndMarineGallons
% IndAgriculturalGallons
% IndGovernmentGallons
% IndOutOfStateGallons
% IndOtherHaulersGallons
% IndTotalGallons
% GrandTotalGallons
% TotalLubTransferedGallons
% TotalIndTransferedGallons
% TotalTransferedGallons

HH=accum(filter(H,'Year',{@eq},year),'dmmmddddddddddddddddadda','A');
netgal=num2cell([HH(:).AGrandTotalGallons] - [HH(:).ATotalTransferedGallons]);
[HH.NetGalReceived]=deal(netgal{:});
