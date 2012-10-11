Annual Hazardous Waste Summary Report

Background:

In 1986, Assembly Woman Sally Tanner sponsored AB 2948, County Hazardous 
Waste Management Plans, which authorized a county, in lieu of preparing 
the hazardous waste portion of a County Solid Waste Management Plan, to 
adopt a county hazardous waste management plan.  The then Department of 
Health Services, Hazardous Waste Management Unit was required to provide 
generator information to assist the Counties in preparing these 
management plans.  This became known as the Tanner Report.  This report 
consisted of summary information of hazardous waste generators with 
waste stream and county information.  Additionally, reports were 
available from hazardous waste manifest data that provided more specific 
information on hazardous waste generators.  In 1995 the two reports were 
blended and the TanGen paper report was created which met the requirements 
of the original legislation and provided complete generator and receiving 
facility information.  Through use, the report became know simply as the 
Tanner Report.  The report is now called the HW Summary Report and is 
provided today on the DTSC Web Site and on CD.

The summary data on are prepared from data extracted from the copies of 
hazardous waste manifests received each year by the Department of Toxic 
Substances Control.  The volume of manifests is typically 900,000-1,000,000 
annually, representing approximately 450,000-500,000 shipments.  Data 
from non-California manifests and continuation sheets, which represent just 
a few percent of the total volume, are not included at the present time.  
Data are extracted from the manifests submitted without correction, and 
therefore may contain some invalid values for data elements.  See the readme 
file for complete disclaimer information.


File Structure:

The summary data in the files are prepared from data extracted
from the copies of hazardous waste manifests received each year
by the Department of Toxic Substances Control.  Data from
non-California manifests and continuation sheets are not included
at the present time.  

Files are included in comma delimited formats, with the following file layouts:
-----------------------------------------------

MANIFEST SUMMARY FILE - tons are summarized for each unique
occurrence of GENERATOR-ID, TSD-ID, CATEGORY-NBR, AND DISPOSAL-
METHOD.
The format of the data is as follows:

GEN_EPA_ID        12   (Generator EPA ID)
GEN_CNTY          02   (Generator Calif. County)
TSD_EPA_ID        12   (TSD EPA ID)
DISP_CNTY         02   (TSD/Disposal Calif County)
CAT_CODE          03   (State Waste Category Code)
METH_CODE         04  (Disposal method Code)
TONS              11   (NUMERIC, 99999.99999)

RECORD LENGTH = 46

Each file name consists of the word TANNER followed by 4 digits which 
represents the year.

FILE NAME     = TANNERxxxx.TXT  (comma delimited data in the above format)
-----------------------------------------------

FACILITY REFERENCE FILE - This file cross-references to the
MANIFEST SUMMARY FILE using EPA_ID as the key to link to
GENERATOR-ID or TSD-ID.  Every ID (generator or TSDF) located
in the Tanner files, is in this Facility file.
The format of the data is as follows: 

EPA_ID                        12
FACILITY-NAME                 35   (FAC_NAME)
FACILITY-STREET1              35   (FAC_ST1)
FACILITY-CITY                 20  (FAC_CITY)
FACILITY-COUNTY               02   (FAC_CNTY)
FACILITY-STATE                02   (FAC_STATE)
FACILITY-ZIP                  09   (FAC_ZIP)
FACILITY-MAILING-STREET1      35  (MAIL_ST1)
FACILITY-MAILING-CITY         20   (MAIL_CITY)
FACILITY-MAILING-STATE        02   (MAIL_STATE)
FACILITY-MAILING-ZIP          09   (MAIL_ZIP)
FACILITY-CONTACT-NAME         35   (CONT_NAME)
FACILITY-CONTACT-PHONE        10   (CONT_PHONE)

RECORD LENGTH = 226
FILE NAME     = FACILITY.TXT  (comma delimited data in the above format)
-----------------------------------------------

WASTE CATEGORY FILE - This file (WASTEC) provides the category codes and their
respective descriptions.
The format of the data is as follows: 

CAT_CODE                      03
CAT_DESC                      150

RECORD LENGTH = 153
RECORD COUNT  = 85
FILE NAME     = WASTEC.TXT  (comma delimited data in the above format)
-----------------------------------------------

DISPOSAL METHOD FILE - This file (METHOD) provides the disposal method
codes and their respective descriptions.
The format of the data is as follows: 

METH_CODE                      04
METH_DESC                      150

RECORD LENGTH = 154
RECORD COUNT  = 28
FILE NAME     = METHOD.TXT   (comma delimited data in the above format)
-----------------------------------------------

CALIF. COUNTY CODE FILE - This file (COUNTY) provides the codes for Calif.
County codes and their respective names.
The format of the data is as follows: 

CNTY_CODE                      02
CNTY_NAME                      150

RECORD LENGTH = 152
RECORD COUNT  = 61
FILE NAME     = COUNTY.TXT   (comma delimited data in the above format)
-----------------------------------------------

