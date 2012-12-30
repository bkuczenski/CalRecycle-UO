==========
Tue Nov 13 22:33:42 PST 2012

Used Oil MFA Documentation


OUTPUT DATA FILES
=================

UO_MFA_results_YYYY-MM-DD.xls
-----------------------------

Includes 3 worksheets:  MD_221 , MD_222_223 , CR

Manifest Data
=============

MD_221 and MD_222_223 report the results of analyzing the manifest data
using facility mass balance.  Note that year 2006 is omitted due to poor
data quality.

Methodology
-----------

A manifest record includes: 

 * description of the waste (California Waste Code),
 * facility ID of the origin facility, 
 * facility ID of the destination facility, 
 * management method code used at the destination facility,
 * quantity of waste transported.

We use the manifest records to estimate generation and disposition of oil
based on a mass balance analysis over all destination facilities.  

1. For each unique facility ID that appears in the corpus, compute flows
into and out of the facility:

  IN   = sum of quantities over all manifests with the facility as TSDF
  term = subset of IN; manifests showing "terminal" method codes.
  OUT  = sum of quantities over all manifests with the facility as generator

1a. Facilities with only outflows (IN==0) are considered strict generators.

1b. Facilities with only inflows (OUT==0) are considered strict processors.

1c. Facilities where both IN>0 and OUT>0 are transfer facilities; perform
mass balance.

2. Terminal method codes imply that the waste is considered to meet its
final disposition at the facility (does not leave the facility as "used
oil".)  We consider the following method codes to be terminal:

 * H010 metals recovery,
 * H020 solvent recovery,
 * H040 destructive incineration,
 * H050 on-site energy recovery,
 * H061 fuel blending for off-site energy recovery,
 * H081 biological treatment,
 * H111 stabilization or fixation prior to disposal
 * H129 other treatment,
 * H132 landfill or surface impoundment,
 * H135 discharge to POTW / NPDES

Manifests containing other method codes, including H039, H077, H101, H103,
H141, and unspecified, are considered to have an ambiguous fate: maybe the
oil is recycled; maybe it is transferred to another facility.  The fate of
these oils is determined by mass balance.

3. The mass balance value b is given by:

   (IN - term) + b = OUT

If b >> 0, that implies a net outflow from the facility, which is
attributed to consolidated collection.

If b << 0, that implies a net inflow to the facility, which is attributed
to oil meeting final disposition.

If b is close to 0 relative to the magnitudes of IN and OUT, the facility
is acting like a transfer station.  The mass balance discrepancy 'b' may
indicate transfer losses or incidental dewatering.

4. Once each facility's mass balance is computed, the results are added
together over all facilities to estimate the size of the total used oil
material flow.


Result Fields
-------------

TotalCollected – Estimated total oil collected in the state.  Includes
 oil transferred from generators to transfer facilities as well as apparent
 consolidation of oil by transfer facilities. 

Consolidated - apparent consolidation of oil by transfer facilities.
 This value is the sum of facility mass balance values for facilities that
 appear to be net generators of oil.  It is assumed that they act as
 consolidating transporters and thus appear as generators on the manifest
 record. 

TotalTransferred - the sum of quantities over all manifests leaving
 transfer facilities.  Includes transfers out of state.

ExportedFromCA - sum of oil meeting final disposition (term + |b| if b<0)
 at facilities outside California.  Included in both TotalTransferred and
 TotalDisposed. 

TotalDisposed - sum of oil meeting final disposition at all facilities.
 TotalDisposed should equal TotalCollected.



CalRecycle Data
===============

Distillation of the CalRecycle used oil management reports.

    Indicators:  

LubSalesCA - Sales of lube oils into the CA market, from CR reports
(excludes export & fee-paid exemptions; includes motor carrier & commerce
exemptions).

IndSalesCA " " " " for industrial oils.
               
LubeCollected - Total reported collections of lube oils over the given
year from CalRecycle hauler data.
               
IndCollected - " " " " for industrial oils.
               
LubeTransferred - Total reported transfers of lube oils over the given
year from CalRecycle transfer data, double counting removed.
               
IndTransferred - " " " " for industrial oils.  Zero prior to 2009.
               
LubeProcessedRpt - reported quantity of lube oil received by processors.
Overstatement of used oil quantity because (1) transfer stations are
included and (2) water fraction and oily water waste streams are included.
               
IndProcessedRpt - " " " for industrial oils.

LubeProcessedRptExCA - " " " Subset of LubeProcessedRpt for facilities
outside CA.  Note substantial increase in 2011.  Manifest Data suggest that
the value is not valid- some facilities appear to be reporting their total
material flows rather than just the ones from California.
               
IndProcessedRptExCA - " " " for industrial oils.
               
LubeProcessedCorr - Same as above, corrected to remove facilities with
nonzero oil received but zero recycled oil production.  This is grounded in
the assumption that these facilities are transfer stations and their oil is
ultimately processed elsewhere (borne out by manifest data).
               
IndProcessedCorr - " " " " for industrial oils.


Facilities Detail
=================

UO_facilities_2004_2011.xls

This spreadsheet uses a pivot table to compare the material flow
information for each facility.  The data are stored in one big table on the
"Data" worksheet.  The different columns can be pulled up as desired on the
"Pivot" worksheet.

The columns have the following meanings:

TSDF_EPA_ID - The EPA ID number of the destination facility (mass balance
node)

FAC_ST - the state in which the facility is located

FAC_NAME - Facility Name according to DTSC records.  Facilities without
records or with incomplete records may show up as just the EPAID number
here.

WC - Waste Code;  221 - Waste Oil or Mixed Oil
     	   	  222 - Oil/Water Separation Sludge
		  223 - Other oil-containing waste

Year - 2004, 2005, 2007-2011.  2006 manifest data are poor quality and
omitted.

GGAL - Used oil apparently generated at the facility. Includes
self-transfers plus mass balance value for net-outflow facilities.

IgGAL - Used oil transferred into the facility from strict generators
inside CA.

ImGAL - Used oil imported from out of state.  (EXCLUDED FROM MASS BALACE
CALCULATION- for information purposes only)

ItGAL - Used oil transferred into the facility from transfer stations
inside CA. (self-transfers excluded; counted as generation)

OGAL - Used oil transferred out of the facility to other facilities in
California.

OxGAL - Used oil transferred to an out-of-state facility.

DGAL - Used oil apparently disposed at the facility.  Includes terminal
flows plus mass balance value for net-inflow facilities.

f - balance fraction.  f = b / max( IN, OUT) 

    if OUT >> IN, then b > 0 so f > 0: facility is a net generaor; f
    indicates the fraction of the throughput that is generated /
    consolidated by the facility directly.  As f -> 1, facility becomes a
    strict consolidator.

    if OUT == IN, b -> 0 so f -> 0: as b reduces in magnitude it begins to
    make sense as an accounting measurement of Transfer gains or losses.

    if OUT << IN, then b < 0 so f < 0: facility is a processor.  f measures
    the fraction of the throughput that meets final disposition at the
    facility.   as f -> -1, the facility becomes a strict processor (like
    DK). 

CR_GAL - Used oil processed (total), as reported to CalRecycle

CR_indGAL - Used oil processed (industrial only), as reported to CalRecycle

CR_prodGAL - Products of used oil, as reported to CalRecycle

CR_residGAL - Residuals and wastes, as reported to CalRecycle

H###GAL - Disposition routes, sorted by management method code.

H900 - Balance Fraction for net-inflow facilities, when |f| > 10% (apparent
recovered oil)

H901 - Balance Fraction for net-inflow facilities, when |f| < 10% (likely
transfer station losses)

All other H###GAL - EPA standard Management Method Codes.


Some equivalencies
------------------

 GGAL + IgGAL + ItGAL = IN

         OGAL + OxGAL = OUT

 DGAL = sum of all disposal flows H###

In any given year:
 sum of OGAL + sum of OxGAL = sum of ItGAL 
 sum of GGAL + sum of IgGAL = sum of DGAL








Observations
============

* The two data sources show largely consistent results.

