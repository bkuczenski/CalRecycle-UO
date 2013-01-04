function EST=est_uo(X,varargin)
% function EST=est_uo(request)
% 
% generates data and output files for ES&T paper on UO material flow
%
% request can be numeric or text, one of:
%
% output opts:
%   num    txt   Output
%  1, 2.1 'T2'  Table 2 "big MFA table"
%  2, 2.2 'F2'  Fig 2 NAICS of Ig + G for sumof 3 waste codes
%  2.21   'F2a' part a Ig
%  2.22   'F2b' part b G
%  3      'F3'  Fig 3 volume by transport distance, yoy
%  4      'F4'  Fig 4 fate + GIS map
%
% internal opts:
%   num   txt    Output
% 101   'D'      EST.D - flow data; uo_activity output
% 201   'NAICS'  EST.NAICS - NAICS lookup by year - fig2a / generators
% 202   'NAICSB' EST.NAICSB - NAICS lookup by year - fig2b / consolidators
% 301   'QDIST'  uo_distance computation by year
%
% expects global MD, Node, GEO_CONTEXT
%
% Returns struct 'T' and shows 'T' to files est_(table|figure){2[ab],3,4}.csv
%
% est_uo(..,'TeX') will output .tex files for figure drawing (to be implemented!).
% The default is to show(T) and output datatool files.
%
% To use this function from a fresh Matlab instance:
%  cd UO
%  load_geo
%  load MD
%  load Node
%
% Creates and saves a data structure EST containing results.

global Facilities MD Node GEO_CONTEXT GEO_REGION

if isstruct(X)
  EST=X;
  request=varargin{1};
  varargin=varargin(2:end);
else
  request=X;
  if exist('EST.mat','file')
    load EST
  else
    EST=struct;
  end
end

if isempty(GEO_CONTEXT)
  error('Unknown GEO_CONTEXT.  Do you need to load_geo ?')
end

TEXOUTPUT=false;
YEARS=[2007:2011];
OIL_FRAC=[0.95 0.5 0.15];
OIL_DENS=0.8935; % kg/L
WC_DENS=OIL_FRAC*OIL_DENS+(1-OIL_FRAC);
METH_REGEXP='^H[0-9]{3}';
FAC_DATA_FILE='../../../../Dropbox/research.local/oil/esthag/EST-Facilities.xlsx';
FAC_DATA_SHEET='Activities';

conv = 3.785; % L per GAL

if ischar(request)
  switch lower(request)
    case {'t2','table2'}
      R=1;
    case {'f2','figure2'}
      R=2.2;
    case {'f2a','figure2a'}
      R=2.21;
    case {'f2b','figure2b'}
      R=2.22;
    case {'f3','figure3'}
      R=3;
    case {'f4','figure4'}
      R=4;
    case 'd'
      R=101;
    case 'naics'
      R=201;
    case 'naicsb'
      R=202;
    case 'qdist'
      R=301;
    otherwise
      error(['unknown fig spec ' request])
  end
else
  R=request;
end

if ~isempty(varargin)
  switch varargin{1}
    case 'TeX'
      TEXOUTPUT=true;
    otherwise
      disp(['ignoring unrecognized arg ']);
  end
end

%% actually do the work

if isempty(Node)
  load Node
end


switch R
  case 1
    if ~isfield(EST,'D')
      EST=est_uo(EST,101);
    end
    D=EST.D;

    %% Table 2 big MFA
    %% do this by transpose
    %% data columns are:
    %%    wc221   L  'TotalDisposed'
    %%    wc222   L  'TotalDisposed'
    %%    wc223   L  'TotalDisposed'
    %%
    %%   uogen    L 'Ig'
    %%   uoconsol L 'G'
    %%   uototal  L sum 
    %%   uotxfr   L 'O+Ox'
    %%
    %%    ww      kg from activity
    %%    hw      kg " "
    %%   other    kg " " or balance against Node.Dist meas
    %%
    %%    valu    kg oil recovered
    %%   uoexp    kg from activity
    %% 
    %%  freight  tkm Node.Dist
    %%  avgdist   km average shipment distance
    hdr={'year','wc221','wc222','wc223','uogen','uoconsol','uototal','uotxfr','ww','hw', ...
        'other','valu','export','freight','dist'};
    data=[ YEARS(:)';
           D.wcD ; % total by waste code
           sum(D.wcIg,1);
           sum(D.wcG,1);
           sum([D.wcIg;D.wcG],1);
           sum(D.wcTx,1);
           sum(D.ww,1);
           sum(D.hw,1);
           sum(D.other,1);
           sum(D.valu,1);
           sum(D.export,1);
           sum(D.freight,1);
           1000*sum(D.freight,1)./sum(D.coll,1)];
    
    mhdr={'Key','Title','Units','Scale','Precision','Term'};
    meta={'Total Collection - WC 221','L',1,'2','';
          'Total Collection - WC 222','L',1,'2','';
          'Total Collection - WC 223','L',1,'2','\n';
          'Direct from Generator','L',1,'2','';
          'Consolidated','L',1,'2','\n';
          'Total Used Oil Collected','L',1,'2','';
          'Total Transfers','L',1,'2','\n';
          'Waste Water','kg',1,'2','';
          'Hazardous Waste','kg',1,'2','';
          'Other / Unknown','kg',1,'2','\n';
          'Dry Oil Recovered','kg',1,'2','';
          'Total Exports','kg',1,'2','\n';
          'Freight','tkm',1,'3','';
          'Average Distance','km',1,'1',''};
               
    T=cell2struct(num2cell(data),hdr);
    
    Tm=cell2struct([hdr(2:end);meta'],mhdr);
    
    show(T,'',{'est_table2.csv',1,1},',*')
    show(Tm,'',{'est_table2meta.csv',1,1},',*')
    
    EST.Table2=T;
    EST.Table2meta=Tm;
    
    % pretty print to screen
    %keyboard
    tw=85;
    rfmt='%26.26s   %-5s ';
    dfmt='%10.3G';
    hfmt='%10.0d';
    fprintf('%s\n','TABLE 2: MFA RESULTS');
    fprintf('%s\n',repmat('=',1,tw));
    fprintf(rfmt,'Indicator','Units');
    fprintf(hfmt,[T.year]);
    fprintf('\n');
    fprintf('%s\n',repmat('-',1,tw));
    for i=1:length(Tm);
      fprintf(rfmt,Tm(i).Title,Tm(i).Units);
      fprintf(dfmt,[T.(Tm(i).Key)]);
      fprintf([Tm(i).Term '\n']);
    end
    fprintf('%s\n',repmat('=',1,tw));
    
  case 2
    % Figure 2
    EST=est_uo(EST,2.21,varargin{:}); return
    EST=est_uo(EST,2.22,varargin{:}); return
    
  case 2.1
    EST=est_uo(EST,1,varargin{:}); return  % perplexing
  case 2.21
    if ~isfield(EST,'NAICS')
      EST=est_uo(EST,'NAICS');
    end

    BN=[];
    field='GAL';
    
    for i=1:length(YEARS)
      QN=EST.NAICS{i};
      QN=accum(QN,'mad','');
      
      B=build_naics(QN,field,.045,2);
      [B.Year]=deal(YEARS(i));
      B=sort(B,'GENNAICS');
      %      B=naics_style(B);
      
      if isempty(BN)
        BN=B;
      else
        BN=[BN;B];
      end
    end

    BN=moddata(BN,'GAL',@(x)(x * 3.785e-6),'ML'); % conv to million liters
    show(select(BN,{'Year','GENNAICS','ML'}),'',{'est_fig2a.csv',1,1},',*')
    
    EST.Fig2a=BN;
    
  case 2.22
    if ~isfield(EST,'NAICSB')
      EST=est_uo(EST,'NAICSB');
    end
    
    field='GGAL';
    BN=[];
    for i=1:length(YEARS)
      RN=EST.NAICSB{i};
      RN=accum(RN,'mad','');
      
      B=build_naics(RN,field,.045);
      [B.Year]=deal(YEARS(i));
      B=sort(B,'GENNAICS');
      
      if isempty(BN)
        BN=B;
      else
        BN=[BN;B];
      end
    end
    
    BN=moddata(BN,field,@(x)(x * 3.785e-6),'ML'); % conv to million liters
    show(select(BN,{'Year','GENNAICS','ML'}),'',{'est_fig2b.csv',1,1},',*')
    
    EST.Fig2b=BN;

  case 3
    field='GAL';
    numbins=50;
    mybins=linspace(-1.5,4,numbins+1);
    tickmarks=[-1 0 1 2 3 4]';
    mhdr={'LOGDISTANCE','distance','barnum'};
    meta=num2cell([tickmarks 10.^tickmarks interp1q(mybins',[1:numbins+1]',tickmarks)-0.5]);
    DNm=cell2struct(meta',mhdr);

    % account for very short distances by adding them to the first bin
    mybins(1)=-2;

    if ~isfield(EST,'QDIST')
      EST=est_uo(EST,'QDIST');
    end
    
    DN=[];
    for i=1:length(YEARS)
      yy=num2str(YEARS(i))
      QN=moddata(EST.QDIST{i},'DISTANCE',@log10,'LOGDISTANCE');
      [S,S1,S2]=bins(QN,'LOGDISTANCE',mybins,'text','DBIN');      %      QN=moddata(QN, 
      Sa=accum(select(S,{field,'CENTERNAMES','DBIN'}),'amm','');
      DO=struct('Year',yy,'LOGDISTANCE',num2cell(S1),'BIN',S2);
      DO=vlookup(DO,'BIN',Sa,'CENTERNAMES',field,'zer');

      if isempty(DN)
        DN=DO(:);
      else
        DN=[DN;DO(:)];
      end
    end

    keyboard
    
    DN=moddata(DN,field,@(x)(x * 3.785e-6),'ML'); % conv to million liters
    show(select(DN,{'Year','LOGDISTANCE','ML'}),'',{'est_fig3.csv',1,1},',*')
    show(DNm,'',{'est_fig3meta.csv',1,1},',*')
    
    EST.Fig3=DN;
    EST.Fig3meta=DNm;

  case 3.1
    % GIS output files for TSDF locations
    % plan to present a US map with markers showing facilities receiving UO by
    % Isum; yearly average over 5 years
    if isempty(Node)
      load Node
    end

    RN=[];
    
    for i=1:length(YEARS)

      yy=num2str(YEARS(i));
      for j=1:3
        wc=num2str(220+j);
        
        nodename=['Rn_' yy '_' wc];
        Rn=fieldop(Node.(nodename),'Isum','#GGAL + #IgGAL + #ItGAL');
        Ng=select(filter(Rn,'Isum',{@ne},0),{'TSDF_EPA_ID','Isum'});
        if isempty(RN)
          RN=Ng(:);
        else
          RN=[RN;Ng(:)];
        end
      end
    end
    RN=accum(RN,'ma','');
    RN=moddata(RN,'Isum',@(x)(x * 3.785e-6 / length(YEARS)),'MLY'); % million
                                                                    % liters per year
    [RN,M]=flookup(RN,'TSDF_EPA_ID','LAT_LONG','bla');
    RN=RN(M);
    [~,M]=filter(moddata(RN,'LAT_LONG',@prod),'LAT_LONG',{@eq},0);    
    RN=RN(~M); % RN(~M) is about 0.5 MLY total
    RN=moddata(RN,'LAT_LONG',@(x)(x(2)),'LONGITUDE');
    RN=moddata(RN,'LAT_LONG',@(x)(x(1)),'LATITUDE');
    RN=sort(RN,'MLY','descend');
    EST.TSDFs=select(RN,{'TSDF_EPA_ID','MLY','LONGITUDE','LATITUDE'});
    show(EST.TSDFs,'',{'est_fig3gis.csv',1,1},',*')
    
        
    
    
  case 4

    Title='FIGURE 4: FATE OF USED OIL';
    
    if ~isfield(EST,'D')
      EST=est_uo(EST,101);
    end
    D=EST.D;
    hdr={'year','rere','dist','dielectric','ca','export','ww','hw', ...
        'other'};
    
    data=[ YEARS(:)';
           sum(D.rere,1);
           sum(D.dist,1);
           sum(D.dielectric,1);
           sum(D.ca,1);
           sum(D.export,1);
           sum(D.ww,1);
           sum(D.hw,1);
           sum(D.other,1)];

    T=cell2struct(num2cell(data),hdr);
    
    mhdr={'Key','Title','Units','Scale','Precision','Term'};
    
    meta={'Re-refining','kt',1e-6,'2','';
          'Distillation','kt',1e-6,'2','';
          'Dielectric Rejuvenation','kt',1e-6,'2','\n';
          'CA RFO Market','kt',1e-6,'2','';
          'Export from CA','kt',1e-6,'2','\n';
          'Waste Water','kt',1e-6,'2','';
          'Hazardous Waste','kt',1e-6,'2','';
          'Other / Unknown','kt',1e-6,'2',''};
               
    Tm=cell2struct([hdr(2:end);meta'],mhdr);
    
    % scale down T
    for i=1:length(Tm)
      T=moddata(T,Tm(i).Key,@(x)(x * Tm(i).Scale));
    end
    
    show(T,'',{'est_fig4.csv',1,1},',*')
    show(select(Tm,{'Key','Title','Units'}),'',{'est_fig4meta.csv',1,1},',*')
    
    EST.Fig4=T;
    EST.Fig4meta=Tm;
    
    % pretty print to screen
    %keyboard
    tw=85;
    rfmt='%26.26s   %-5s ';
    dfmt='%10.4G';
    hfmt='%10.0d';
    fprintf('%s\n',Title);
    fprintf('%s\n',repmat('=',1,tw));
    fprintf(rfmt,'Indicator','Units');
    fprintf(hfmt,[T.year]);
    fprintf('\n');
    fprintf('%s\n',repmat('-',1,tw));
    for i=1:length(Tm);
      fprintf(rfmt,Tm(i).Title,Tm(i).Units);
      fprintf(dfmt,[T.(Tm(i).Key)]);
      fprintf([Tm(i).Term '\n']);
    end
    fprintf('%s\n',repmat('=',1,tw));

    
    

    %%%
    %%%
    %%%
  case 101
    Fac=xls2struct(FAC_DATA_FILE,FAC_DATA_SHEET,{'n','s','s','s','s','n','s'});
    [Fac(isnan([Fac.FRACTION])).FRACTION]=deal(1);
    for j=1:3
      wc=num2str(220+j);
      FacWaste=filter(Fac,'WASTE_CODE',{@rexegp},wc);
      for i=1:length(YEARS)
        yy=num2str(YEARS(i));
        nodename=['Rn_' yy '_' wc];
        Rn=Node.(nodename);
        D.wcD(j,i)=sum([Rn.DGAL]) * conv ;  % GAL->L
        D.wcG(j,i)=sum([Rn.GGAL]) * conv ;  % GAL->L
        D.wcIg(j,i)=sum([Rn.IgGAL]) * conv ;
        D.wcTx(j,i)=sum([Rn.OGAL]+[Rn.OxGAL]) * conv ;
        
        An=uo_activity(Node.(nodename),METH_REGEXP,FacWaste); 
        
        D.ww(j,i)=sum([An.WW]) * conv; % assume 1L = 1kg
        D.hw(j,i)=sum([An.HW]) * conv; % assume 1L = 1kg
        D.other(j,i)=sum([An.Other]) * conv; % assume 1L = 1kg
        D.rere(j,i)=sum([An.Rere]) * conv * OIL_DENS;
        D.dist(j,i)=sum([An.Dist]) * conv * OIL_DENS;
        D.ca(j,i)=sum([An.CA]) * conv * OIL_DENS;
        D.dielectric(j,i)=sum([An.Dielectric]) * conv * OIL_DENS;
        D.export(j,i)=sum([An.Export]) * conv * OIL_DENS;
        
        D.valu(j,i)=sum([D.rere(j,i) D.dist(j,i) D.ca(j,i) D.export(j,i) D.dielectric(j,i)]);
        
        Dist=filter(Node.Dist,{'Year','WC'},{@eq,@strcmp},{YEARS(i),wc});
        D.freight(j,i)=Dist.('Freight_tkm'); % in tkm
        D.coll(j,i)=Dist.('Collected_kg');  % in kg
        
      end
    end
    EST.D=D;
    keyboard

  case 201
    % NAICS GEN
    if isempty(MD)
      load MD
    end
    
    field='GAL';
    for i=1:length(YEARS)
      yy=num2str(YEARS(i));
      QN=[];
      for j=1:3
        wc=num2str(220+j);

        manname=['Q_' yy '_' wc];
        fprintf('Doing %s\n',manname)
        
        Q=MD.(manname);
        
        [~,istx]=filter(Q,'GEN_EPA_ID',{@ismember},{unique({Q.TSDF_EPA_ID})});
        [~,isimport]=filter(Q,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},{GEO_REGION},{1,0});
        isimport=isimport(:,end);

        Qg=select(Q(~istx & ~isimport),{'GEN_EPA_ID',field});
        Qg=flookup(Qg,'GEN_EPA_ID','NAICS_CODE','bla');
        
        Qg=mvfield(Qg,'NAICS_CODE','GENNAICS');
        
        Qg=expand(Qg,'GENNAICS',' ',field);
        
        Qg=accum(Qg,'dam','');

%        Qg=moddata(Qg,field,@floor);
        if isempty(QN)
          QN=Qg;
        else
          QN=[QN;Qg];
        end
      end
      EN{i}=QN;
    end

    EST.NAICS=EN;
  
  case 202
    if isempty(Node)
      load Node
    end

    field='GGAL';
    for i=1:length(YEARS)

      yy=num2str(YEARS(i));
      RN=[];
      for j=1:3
        wc=num2str(220+j);
        
        nodename=['Rn_' yy '_' wc];
        Rn=Node.(nodename);
        Ng=select(filter(Rn,field,{@ne},0),{'TSDF_EPA_ID',field});

        Ng=flookup(Ng,'TSDF_EPA_ID','NAICS_CODE','bla');
        
        Ng=mvfield(Ng,'NAICS_CODE','GENNAICS');
        
        Ng=expand(Ng,'GENNAICS',' ',field);
        Ng=moddata(Ng,field,@floor);
        
        Ng=accum(Ng,'dam','');

        if isempty(RN)
          RN=Ng;
        else
          RN=[RN;Ng];
        end
      end
      EN{i}=RN;
    end

    EST.NAICSB=EN;
    
  case 301
    if isempty(MD)
      load MD
    end
    
    field='GAL';
    % QDIST
        
    for i=1:length(YEARS)
      yy=num2str(YEARS(i));
      QN=[];
      for j=1:3
        wc=num2str(220+j);

        manname=['Q_' yy '_' wc];
        fprintf('Doing %s\n',manname)
        
        Q=MD.(manname);
        
        isself=strcmp({Q.GEN_EPA_ID},{Q.TSDF_EPA_ID});
        [~,isimport]=filter(Q,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},{GEO_REGION},{1,0});
        isimport=isimport(:,end);

        Qd=select(Q(~isself' & ~isimport),{'GEN_EPA_ID','TSDF_EPA_ID',field});
        
        if isempty(QN)
          QN=Qd;
        else
          QN=[QN;Qd];
        end
      end
      QDIST{i}=uo_distance(QN); % look up distance from lat + long
%      iszero=[QN.DISTANCE]==0;
      QDIST{i}=rmfield(QDIST{i},{'GEN_LATLONG','TSDF_LATLONG'});
    end
    EST.QDIST=QDIST;

    
  otherwise
    error(['Unknown case ' num2str(R)]);
end

function tb=dlookup(ta,dat,fld,arg)
if nargin<4
  arg=fld;
end
tb=vlookup(ta,'Year',dat.(fld),'Year','Value','nan');
tb=mvfield(ta,'Value',arg);
