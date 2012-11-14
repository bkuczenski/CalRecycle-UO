function Eout=txfr_rec(Ein,inter,opt)
% function E=txfr_rec(E,year)
% function E=txfr_rec(year)
%
% Allows the user to attempt to reconcile transfer station data between the CR and
% MD data sets by showing them side by side.  Builds an outcome table E showing the
% results of the comparison.  this will accumulate information across runs.
%
% R=txfr_rec(Rpart)
% Continue work where you left off!

use_md2=true;

if use_md2
  md_prefix='MD-node2_';
else
  md_prefix='MD-node_';
end

global Facilities
do_bad_EPAIDs=false; % already done in md_node

if nargin<2
  if isnumeric(Ein) & Ein>1900 & Ein<2100
    % 
    year=Ein;
    E=[];
  elseif isstruct(Ein)
    % continue where we left off
    Rpart=Ein.Rpart;
    year=Ein.year;
    E=Ein.E;
    if do_bad_EPAIDs
      NM=Ein.NM;
    end
  else
    disp('Don''t know what to do with first input arg')
    keyboard
  end
  inter=0;
else
  E=Ein.E;
  if do_bad_EPAIDs
    NM=Ein.NM;
  end
  Rpart=Ein.Rpart;
  if isnumeric(inter) & inter>1900 & inter<2100
    year=inter;
    inter=0;
  else
    year=Ein.year;
  end
end

yy=num2str(year);
%% ---------------------------------------------------------------------------

if isempty(E) % start from scratch
  
  % load all relevant files w full manifests
  CR=load(['CR_' yy '.mat']);
  MD1=load([md_prefix yy '_221.mat']);
  MD2=load([md_prefix yy '_222.mat']);
  MD3=load([md_prefix yy '_223.mat']);
  
  Rpart.Rn=CR.(['CR_' yy]).Rnode;
  Rpart.Tn{1}=MD1.MD.Tn;%(['Tn_' yy '_221']);
  Rpart.Tn{2}=MD2.MD.Tn;%(['Tn_' yy '_222']);
  Rpart.Tn{3}=MD3.MD.Tn;%(['Tn_' yy '_223']);
  Rpart.year=year;

  % make a master list of EPAIDs
  
  E=cell2struct(unique({Rpart.Rn.TSDF_EPA_ID,...
                      Rpart.Tn{1}.TSDF_EPA_ID,...
                      Rpart.Tn{1}.TSDF_EPA_ID,...
                      Rpart.Tn{1}.TSDF_EPA_ID}),'EPAID');

  if do_bad_EPAIDs
    % now detect bad EPAIDs
    [~,M]=flookup(E);
    NM=E(~M);
    E=E(M); % come back to the bads later
    NM=mvfield(NM,'EPAID','BAD_EPAID');
    NM=vlookup(NM,'BAD_EPAID',E,'EPAID','EPAID','strdist2');
    %  NMmatch=strnearest({NM(:).EPAID},{EM(:).EPAID},2,'first'); % only allow dist <=2
    %  NMmatch(cellfun(@isempty,NMmatch))=deal({0});
    %  keyboard
    
    [E(:).Year]=deal(year);
    [NM(:).Year]=deal(year);
    
    E=buildRpart(E,Rpart,'EPAID');
    NM=buildRpart(NM,Rpart,'BAD_EPAID');
    
    % first do non-matches
    for i=1:length(NM)
      fprintf(1,'\nLooking up BAD_EPAID %s...\n',NM(i).BAD_EPAID);
      [classif,MDnet,CRnet]=classify(NM(i).BAD_EPAID,yy,MD1,MD2,MD3,CR);
      % if ~strcmp(classif,'X-#-- ')
      %   fprintf(1,'Surprising non-sink facility.')
      %   keyboard
      % end
      NM(i).MDnet=MDnet;
      NM(i).CRnet=CRnet;
    end
    NM=accum(NM,'aaadmmaaaaaaaaaaa','');
    [NM(:).Eval]=deal('');
    [NM(:).Type]=deal('');
    
    try
      NM=orderfields(NM,[3 4 5 1 2 6:14 18 19 15 16 17]);
    catch
      keyboard
    end
  else
    [E(:).Year]=deal(year);
    E=buildRpart(E,Rpart,'EPAID');
  end
  inter=99;
%  keyboard
else
  % load files based on inter
  CR=load(['CR_' yy '.mat']);
  MD1=load([md_prefix yy '_221.mat']);
  MD2=load([md_prefix yy '_222.mat']);
  MD3=load([md_prefix yy '_223.mat']);
  disp('load stuff here')
end

% ===========================================================================
% now step through them one at a time, presenting the user with detailed
% information and prompting for an interpretation.
%
% eventually: interaction parameterized in inter arg

switch inter
  case {0,1,2}
    % run through the list; display digest; obtain evaluative notes
    if ~isfield(E,'Eval')
      [E(:).Eval]=deal('');
      q='';
    end
    if ~isfield(E,'Type')
      [E(:).Type]=deal('');
    end
    if ~isfield(E,'MDnet')
      [E(:).MDnet]=deal(0);
      q='';
    end
    if ~isfield(E,'CRnet')
      [E(:).CRnet]=deal(0);
    end
    
    for i=1:length(E)
      classif=E(i).Type;
      fprintf(1,'\nLooking up %s...\n',E(i).EPAID);

      if isempty(classif) | inter==2
        [classif,MDnet,CRnet]=classify(E(i).EPAID,yy,MD1,MD2,MD3,CR);
      else
        MDnet=E(i).MDnet;
        CRnet=E(i).CRnet;
      end
      % show md_node2 classification
      show(select(E(i),{'C221','C222','C223'}),'','','\t',true);
      if do_bad_EPAIDs
        % if there's non-matching manifests, show them here
        if any(strcmp({NM.EPAID},E(i).EPAID))
          fprintf(1,'Non-matching manifests, total:\n',E(i).CR_bal);
          NMi=filter(NM,'EPAID',{@strcmp},E(i).EPAID);
          show(NMi,'','','\t',true);
          A=accum([E(i) rmfield(NMi,'Count')],'aaammaaaaaaaaaccaa',{'','',''});
          A=orderfields(A,[3 4 5 1 2 6:14 17 18 15 16 19]);
          E(i)=rmfield(A,'Count');
          MDnm=NMi.MDnet;
          CRnm=NMi.CRnet;
        else
          MDnm=0;
          CRnm=0;
        end
      end
      
      fprintf(1,'CR: Reported node balance = %f\n',E(i).CR_bal);
      
      fprintf(1,'Type Classification: %s\n',classif);
      if inter==0
        zz=ifinput('Evaluation (zz to save+quit): ',q,'s');
      else % inter>0: preprocess; 1-skip already done; 2- revisit already done
        q=E(i).Eval;
        if isempty(q)
          % make hardcoded prerocessing evals 
          if strcmp(classif,'X-#-- ')
            zz=['MD sink - ' subsref(E(i).EPAID,substruct('()',{[1:2]}))...
                ' - ' num2str(floor(MDnet)) ' GAL' ]
          else
            zz=ifinput('Evaluation (zz to save+quit): ',q,'s');
          end
        else
          if inter==2
            fprintf('Evaluation: %s %s\n',classif,q);
            if strcmp(ifinput('Reclassify? y/n','n','s'),'y')
              zz=input('New eval: ','s');
            else
              zz=q;
            end
          else
            zz=q;
          end
        end
      end
      if strcmp(zz,'zz')
        disp('OK come back soon')
        break
      elseif strcmp(zz,'qq')
        keyboard
      else
        fprintf('Evaluation: %s %s\n',classif,zz);
        E(i).Eval=zz;
        E(i).Type=classif;
        E(i).MDnet=MDnet;
        E(i).CRnet=CRnet;
      end
    end
    
  case 3
    % compare fac_rec with classify
    if ~isfield(E,'Eval')
      [E(:).Eval]=deal('');
      q='';
    end
    if ~isfield(E,'Type')
      [E(:).Type]=deal('');
    end
    for i=1:length(E)
      classif=E(i).Type;
      fprintf(1,'\nLooking up %s...\n',E(i).EPAID);

      [classif,MDnet,CRnet]=classify(E(i).EPAID,yy,MD1,MD2,MD3,CR);
      fprintf(1,'%s\n','Facility reconciliation output:')
      fac_rec(E(i).EPAID,year);
      fprintf(1,'Type Classification: %s\n',classif);
      zz=ifinput('Evaluation (zz to save+quit): ',q,'s');
      if strcmp(zz,'zz')
        disp('OK come back soon')
        break
      elseif strcmp(zz,'qq')
        keyboard
      else
        fprintf('Evaluation: %s %s\n',classif,zz);
        E(i).Eval=zz;
        E(i).Type=classif;
        E(i).MDnet=MDnet;
        E(i).CRnet=CRnet;
      end
    end
        
  case 11
    % re-run; add in MDnet and CRnet
    for i=1:length(E)
      if ~isfield(E,'Eval')
        E(i).Eval='';
        q='';
      end
      if ~isfield(E,'Type')
        E(i).Type='';
      end
      classif=E(i).Type;
      fprintf(1,'\nLooking up %s...\n',E(i).EPAID);

      [classif,MDnet,CRnet]=classify(E(i).EPAID,yy,MD1,MD2,MD3,CR);
      E(i).MDnet=MDnet;
      E(i).CRnet=CRnet;
    end
    
  case 21
    % lookup epaid
    [classif,MDnet,CRnet]=classify(opt,yy,MD1,MD2,MD3,CR);
    ind=find(strcmp({E.EPAID},opt));
    % show md_node2 classification
    show(select(E(ind),{'C221','C222','C223'}),'','','\t',true);
    fac_rec(E(ind).EPAID,year);
    if isfield(E,'Eval')
      q=E(ind).Eval;
      fprintf('Evaluation: %s %s\n',classif,q);
      if strcmp(ifinput('Reclassify? y/n','n','s'),'y')
        E(ind).Eval=input('New eval: ','s');
        E(ind).Type=classif;
      end
    end

  case 41
    % heuristic determination of fates
    % run for a given year
    % pare down E to 
    
    
  case 51
    % manual, accretive determination of fates
    

  case 99
    disp('Finished setting up.')
  otherwise
    keyboard
end

Eout.year=year;
Eout.E=E;
Eout.Rpart=Rpart;
if do_bad_EPAIDs
  Eout.NM=NM;
end



% ---------------------------------------------
function [classif,MDnet,CRnet]=classify(EPAID,yy,MD1,MD2,MD3,CR)

% lookup EPAID
% display:
% facility lookup info
% inbound 221, 222, 223 by method code and total
% outbound 221, 222, 223 by top 3 destinations
% difference
% inbound CR by method code
% outbound CR by top 3 destinations
%
% Type classification: XXbXXb  MDin;MDout;bal;CRin;CRout;bal
% - none
% X present
% b=balance type. 
% + net source (MDnet,CRnet<0)
% # net sink (MDnet,CRnet>0)
%
% inter=0
% prompt user for annotation- at this point, an uninterpreted text string
% inter=1
% preclassify if: strict MD sink

global Facilities

try
  MD_in=[filter(MD1.MD.(['Q_' yy '_221']),'TSDF_EPA_ID',{@strcmp},EPAID);
         filter(MD2.MD.(['Q_' yy '_222']),'TSDF_EPA_ID',{@strcmp},EPAID);
         filter(MD3.MD.(['Q_' yy '_223']),'TSDF_EPA_ID',{@strcmp},EPAID)];
catch
  disp('MD_in')
  keyboard
end
disp(Facilities(FACILITY_lookup(EPAID)));
disp('MD: Inbound by wastecode by method code')
if isempty(MD_in)
  disp('None');
  gross_in=0;
  classif='-';
else
  MD_in=accum(MD_in,'ddmdmma','');
  show(MD_in,'','','\t',true);
  gross_in=accum(MD_in,'dddad','');
  gross_in=gross_in.GAL;
  classif='X';
end
MD_out=[filter(MD1.MD.(['Q_' yy '_221']),'GEN_EPA_ID',{@strcmp},EPAID);
        filter(MD2.MD.(['Q_' yy '_222']),'GEN_EPA_ID',{@strcmp},EPAID);
        filter(MD3.MD.(['Q_' yy '_223']),'GEN_EPA_ID',{@strcmp},EPAID)];
disp('MD: Outbound by wastecode by destination and method')
if isempty(MD_out)
  disp('None');
  gross_out=0;
  classif=[classif '-'];
else
  MD_out=accum(MD_out,'ddmdmma','');
  show(flookup(MD_out),'','','\t',true);
  gross_out=accum(MD_out,'dddad','');
  gross_out=gross_out.GAL;
  classif=[classif 'X'];
end
MDnet=gross_in-gross_out;
if MDnet<0
  classif=[classif '+'];
elseif MDnet==0
  classif=[classif ' '];
else
  classif=[classif '#'];
end

fprintf(1,'MD: Apparent disposal = Net inflow = %f\n\n' , MDnet);

% CR
CR_in=filter(CR.(['CR_' yy]).(['Q_' yy]),'TSDF_EPA_ID',{@strcmp},EPAID);
disp('CR: Inbound by wastecode by method code')
if isempty(CR_in)
  disp('None');
  cross_in=0;
  classif=[classif '-'];
else
  CR_in=accum(CR_in,'ddmdmma','');
  show(CR_in,'','','\t',true);
  cross_in=accum(CR_in,'dddad','');
  cross_in=cross_in.GALLONS;
  classif=[classif 'X'];
end
CR_out=filter(CR.(['CR_' yy]).(['Q_' yy]),'GEN_EPA_ID',{@strcmp},EPAID);
disp('CR: Outbound by wastecode by destination and method')
if isempty(CR_out)
  disp('None');
  cross_out=0;
  classif=[classif '-'];
else
  CR_out=accum(CR_out,'ddmdmma','');
  show(flookup(CR_out),'','','\t',true);
  cross_out=accum(CR_out,'dddad','');
  cross_out=cross_out.GALLONS;
  classif=[classif 'X'];
end
CRnet=cross_in-cross_out;
if CRnet<0
  classif=[classif '+'];
elseif CRnet==0
  classif=[classif ' '];
else
  classif=[classif '#'];
end
fprintf(1,'CR: Apparent disposal = net inflow = %f\n',CRnet);

% ----------------------------------------
function E=buildRpart(E,Rpart,EPAID)
if nargin<3 EPAID='EPAID'; end

n=length(fieldnames(E));
E=mvfield(vlookup(E,EPAID,Rpart.Rn,'TSDF_EPA_ID','Tx_In','zero'),'Tx_In','CR_TxIn');
E=mvfield(vlookup(E,EPAID,Rpart.Rn,'TSDF_EPA_ID','Tx_Out','zero'),'Tx_Out','CR_TxOut');
E=mvfield(vlookup(E,EPAID,Rpart.Rn,'TSDF_EPA_ID','balance','zero'),'balance','CR_bal');
for i=1:3
  E=mvfield(vlookup(E,EPAID,Rpart.Tn{i},'TSDF_EPA_ID','Class','zero'),'Class',...
            ['C22' num2str(i)]);
  E=mvfield(vlookup(E,EPAID,Rpart.Tn{i},'TSDF_EPA_ID','TxIn','zero'),'TxIn',...
            ['MD22' num2str(i) '_In']);
  E=mvfield(vlookup(E,EPAID,Rpart.Tn{i},'TSDF_EPA_ID','TxOut','zero'),'TxOut',...
            ['MD22' num2str(i) '_Out']);
  E=mvfield(vlookup(E,EPAID,Rpart.Tn{i},'TSDF_EPA_ID','DispGAL','zero'),'DispGAL',...
            ['MD22' num2str(i) '_x']);
end
E=orderfields(E,[n+[1 2 3] 1:n n+[4:15]]);
%    2 3 4 1 5:13]);
