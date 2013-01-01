%%=========================================================================
%%=========================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% CONFIGURATION HAPPENS HERE!
%% 
%% Make changes to the below lines to tune the file to your operating 
%% conditions.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

VALID_USERS={'BK','TZ','AH'};
while ~exist('USER','var')
  fprintf('Valid users: %s', VALID_USERS{1})
  fprintf(', %s',VALID_USERS{2:end})
  fprintf('\n')
  uu=ifinput('Select user','BK','s')
  if any(strcmp(uu,VALID_USERS))
    USER=uu;
  end
end
fprintf('Loading config for user %s\n',USER);

%% Select which parts of the MFA to run
YEARS=[2004 2005 2007:2011];
RCRA_YEARS=[2005 2007 2009];
WCs=221:223;

%% ----------------------------------------
%% these 3 params only need to be set to 'true' to force a reload- 
%% during normal operation the operations will be performed as needed if the data
%% fields are not present.
READ_FACILITIES = false;
READ_NAICS      = false;
READ_LAT_LONG   = false;
GEN_DISTANCE    = false;  %% compute freight requirements
%% ----------------------------------------
%% These are used to correct data in an intermediate state and should be left
%% false pretty much of the time.
UNITCONV_MD     = false;  %% force a unit conversion from TONS to GAL
RE_CORR_METH    = false;  %% re-apply method-code correction

%% ----------------------------------------
%% Normal Functionality
LOAD_MD_NODE    = false;  %% whether to reload of data from disk each run
GEN_MD          = false;   %% generate manifest data (if not already generated)
GEN_NODE        = false;   %% compute node mass balances
FORCE_GEN_NODE  = false;  %% force re-computation of node mass balances
LOAD_CR_PROC    = false;   %% load CalRecycle data + append to nodes
FORCE_CR_PROC   = false;  %% force reload CalRecycle data
GEN_RCRA        = false;  %% generate RCRA manifest data + node mass balances
GEN_NODE_PIVOT  = false;   %% generate pivot table
APPLY_FAC_DATA  = true;  %% Compute node activity levels from Facilities data
FORCE_FAC_DATA  = true;  %% force a reload of Facilities spreadsheet
COMPUTE_ACTIVITY = true; %% compute aggregate (MFA-LCA) activity levels

PUBLISH_DATA    = true;   %% publish generated spreadsheets to FILE_EXCHANGE

%% ----------------------------------------
%% INPUT FILES
%% Location of facility description data in csv format
% modified to include DESTINATION_UNKNOWN, SOURCE_UNKNOWN, and custom additions
FACILITIES_FILE='HWTS_FACILITIES_2007_2011.csv'; 
NAICS_FILE='HWTS_FACILITIES_NAICS.csv';
LAT_LONG_FILE='reduced_ZIP_proxy_facilities_mod.csv';

DIST_SCALE=1.2;  % factor between great-circle distance and on-road distance

FACILITIES_PREFIX='../FacilityData/';

TANNER_PREFIX='../TannerData/'; % path to Tanner report data - each year in 'TannerYYYY'
                          % subdir - list of manifest files is hardcoded into
                          % uo_load (based on downloadable data)
CALRECYCLE_PREFIX='../CalRecycleData/'; %% path to CalRecycle data - need
                                    % CR-processor.csv

FAC_DATA_FILE='Facilities.xlsx';
FAC_DATA_SHEET='Activities';

MFA_RESULTS_FILE=['UO_MFA_Results-' date '.xls'];

%% ----------------------------------------
%% Output files - named PREFIX_year[_endyear].xls
NODE_PIVOT_PREFIX='UO_facilities';
ACTIVITY_FILE_PREFIX='UO_activity';


%% ----------------------------------------
%% Management Method Codes we're interested in
METH_REGEXP='^H[0-9]{3}';  % regexp to match all method codes
TANNER_DISP={'H900','H901','H900'};  % net flows into a facility are given this code
TANNER_CUTOFF=[-0.1 0]; % cutoff between disp codes ; values above 0 are import adjustments
TANNER_TERMINAL={'H010','H020','H040','H050','H061','H077','H081','H111','H129','H132', ... 
                 'H135'}; % these codes are considered "terminal" & do not add to
                          % the quantity of oil to TANNER_DISP 

% H077 should be treated like H135

% The following codes (1) are valid, (2) show up in the data, and (3) have not
% been incorporated and are therefore interpreted as H039:
% H101 (9x), H103 (2x), H121 (corrected from H221, 1x), H122 (1x), H123
% (5x), H131 (4x), H134 (1x), totalling 318,000 gallons over 8 years.

% of these, H101, H123 can reasonably be considered to produce RFO and
% should properly count as H039 (totalling 254,000 gal)

% The rest are just not worth considering.


switch USER
  case 'BK'
    %% Output Files
    FILE_EXCHANGE_PREFIX=['../../../../Dropbox/research.bren/CalRecycle-Oil/'];
  case 'TZ'
    FILE_EXCHANGE_PREFIX='C:/tzink/Dropbox/School/PhD/Research/Projects & Papers/CalRecycle Used Oil LCA/';
  case 'AH'
    
  otherwise
    error(['Invalid user ' USER])
end

FILE_EXCHANGE=[FILE_EXCHANGE_PREFIX 'Working Documents/Data Collection/MFA/'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% END CONFIG
%% 
%% Only nake changes above this line.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%=========================================================================
%%=========================================================================
