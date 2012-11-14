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
YEARS=2007:2011;
RCRA_YEARS=[2007 2009];
WCs=221:223;

READ_FACILITIES = true;
READ_NAICS      = true;
LOAD_MD_NODE    = false;
GEN_MD          = true;
UNITCONV_MD     = false;
RE_CORR_METH    = false;
GEN_NODE        = true;
FORCE_GEN_NODE  = false;
LOAD_CR_PROC    = true;
FORCE_CR_PROC   = true;
GEN_RCRA        = true;
GEN_NODE_PIVOT  = true;
PUBLISH_DATA    = true;
APPLY_FAC_DATA  = true;
FORCE_FAC_DATA  = true;
COMPUTE_ACTIVITY = true;

%% INPUT FILES
%% Location of facility description data in csv format
% modified to include DESTINATION_UNKNOWN, SOURCE_UNKNOWN, and custom additions
FACILITIES_FILE='HWTS_FACILITIES_2007_2011.csv'; 
NAICS_FILE='HWTS_FACILITIES_NAICS.csv';

FACILITIES_PREFIX='../FacilityData/';

TANNER_PREFIX='../TannerData/'; % path to Tanner report data - each year in 'TannerYYYY'
                          % subdir - list of manifest files is hardcoded into
                          % uo_load (based on downloadable data)
CALRECYCLE_PREFIX='../CalRecycleData/'; %% path to CalRecycle data - need
                                    % CR-processor.csv

  
NODE_PIVOT_PREFIX='UO_facilities';
ACTIVITY_FILE_PREFIX='UO_activity';

FAC_DATA_FILE='Facilities.xlsx';
FAC_DATA_SHEET='Activities';



%% Management Method Codes we're interested in
METH_REGEXP='^H[0-9]{3}';  % regexp to match all method codes
TANNER_DISP={'H900','H901'};  % net flows into a facility are given this code
TANNER_CUTOFF=-0.1; % cutoff between disp codes
TANNER_TERMINAL={'H010','H020','H040','H050','H061','H081','H111','H129','H132', ...
                 'H135'}; % these codes are considered "terminal" & do not add to
                          % the quantity of oil to TANNER_DISP 

% The following codes (1) are valid, (2) show up in the data, and (3) have not
% been incorporated and are therefore interpreted as H039:
% H077 (4x), H101 (9x), H103 (2x), H121 (corrected from H221, 1x), H122 (1x), H123
% (5x), H131 (4x), H134 (1x), totalling 318,000 gallons over 8 years.

% of these, H077, H101, H123 can reasonably be considered to produce RFO and
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
