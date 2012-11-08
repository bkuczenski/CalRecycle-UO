function Rn = uo_node(Q,T,RC)
% function Rn = uo_node(Q,T,RC)
%
% Turns a manifest record Q into a node mass balance Rn.  Q should have the
% following fields:
% SRC 
% SRC_META 
% DEST 
% DEST_META 
% FLOW_ID 
% METH_CODE 
% QTY 
% 
% SRC_META and DEST_META are used in computations if necessary.
%
% T specifies a set of method codes that are taken to be 'terminal'.  default if
% none specified: H040, H050, H061, H132, H135
%
% RC is the method code assigned to nonterminal flows that meet disposition at the
% facility.  Default: H999 
%
% A facility list is constructed based on the set of destination facilities.
%
% The facility list is assumed to be already corrected via EPAID.Corr
% 
% The remaining unique facilities are subjected to the following measurements:
%  Ia - inflows from self
%  I  - inflows from same state (excl self) = Ig (from gen) + It (from other Tx)
%  Im - inflows from out of state
%  O  - outflows to same state (excl self)
%  Ox - outflows to out of state
%  T  - literal terminal flows
%
% The mass balance is computed:
%
% Ia + I + Im + inflow balance (b) = O + Ox + T
%
% The balance can be measured in terms of the fraction of inflow:
%
% balance fraction f = b / max ( [ sum(I) , sum(O) ] )
%
% if O > I, then b>0: facility is a net generaor; f indicates the fraction of
% throughput that is collected- * primary fraction of production
%
% If O == I, b -> 0; so as b reduces in magnitude it begins to make sense as an
% accounting measurement (of tx gains or losses)
%
% As O becomes < I, b measures the fraction of inflow to final disposition.  As O ->
% 0, b -> 1 and the facility becomes DK: a strict processor.
%
% The derived measurements are:
%  G  - net generated primary material (Ia + b if b > 0)
%  D  - net disposed intermediate material (T - b if b < 0)
%  b  - inflow balance
%  f  - balance fraction
%  
% Last, the fates of the net disposal are given by METH_CODE, with balances where
% b<0 assigned to method code supplied in RC.
%
% Reported Flows:
%  G, Ig, It, Im, O, Ox, D, f, RC, {T}

% base all this around a boolean record selector
% to begin with, our job is easy since EPAIDs have all been corrected
% we want to parse the flows in three ways: 
% by source: self; import; in-state gen; in-state tx
% by dest: (ex self) export, in-state
% by method: terminal, nonterminal

global GEO_REGION
FN=fieldnames(Q);
QTY=FN{7};

if nargin<3
  RC='H999';
end

%% PART 1
%% come up with binary lists

isself=strcmp({Q.GEN_EPA_ID},{Q(:).TSDF_EPA_ID});
isself=isself(:);
[~,isimport]=filter(Q,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},{GEO_REGION},{1,0});
isimport=isimport(:,end);
[~,isexport]=filter(Q,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},{GEO_REGION},{0,1});
isexport=isexport(:,end);
Ts=unique({Q.TSDF_EPA_ID});
[~,istx]=filter(Q,'GEN_EPA_ID',{@ismember},{Ts});
if isempty(T)
  isterminal=repmat(false,length(Q),1);
else
  [~,isterminal]=filter(Q,'METH_CODE',{@ismember},{T});
end

%% PART 2
%% apply those lists and accum over facilities

% inflows include all flows
F.Ia = accum(Q(isself),'ddmddda','Ia');
F.Im = accum(Q(isimport),'ddmddda','Im');
F.Ig = accum(Q(~isself & ~isimport & ~istx),'ddmddda','Ig');
F.It = accum(Q(~isself & ~isimport & istx),'ddmddda','It');

% terminal flows are a subset- accum over destination facilities
F.T  = accum(Q(isterminal),'ddmddda','T');

% outflows only include flows from facilities in Ts, excl self tx
F.O  = accum(Q(istx & ~isimport & ~isexport & ~isself),'mddddda','O');
F.Ox = accum(Q(istx & isexport & ~isself), 'mddddda','Ox'); % flows that are not istx are
                                                  % counted as inflows but not outflows

%% PART 3
%% Build mass balance table
Rn = struct('TSDF_EPA_ID',Ts); % already sorted
Rn = vlookup(Rn,'TSDF_EPA_ID',F.Ia,'TSDF_EPA_ID',['Ia' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.Ig,'TSDF_EPA_ID',['Ig' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.It,'TSDF_EPA_ID',['It' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.Im,'TSDF_EPA_ID',['Im' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.O,'GEN_EPA_ID',['O' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.Ox,'GEN_EPA_ID',['Ox' QTY],'zero');
Rn = vlookup(Rn,'TSDF_EPA_ID',F.T,'TSDF_EPA_ID',['T' QTY],'zero');


%% PART 4
%% Derived Measurements

Rn = fieldop(Rn,'Osum',[' #O' QTY ' + #Ox' QTY ]);
Rn = fieldop(Rn,'Isum',[' #Ia' QTY ' + #Im' QTY ' + #Ig' QTY ' + #It' QTY ]);
Rn = fieldop(Rn,'b',[' #Osum + #T' QTY ' - #Isum' ]);
Rn = fieldop(Rn,'f','#b ./ max([ #Osum; #Isum])');
Rn = fieldop(Rn,[RC QTY],' abs( - min([ #b ; zeros(size(#b))]))');
Rn = fieldop(Rn,['D' QTY],[' #T' QTY ' + #' RC QTY]);
Rn = fieldop(Rn,['G' QTY],[' #Ia' QTY ' + max([ #b ; zeros(size(#b))])']);


%% PART 5
%% METH_CODE Totals

if any(isterminal)
  P = pivot(Q(isterminal),'TSDF_EPA_ID','METH_CODE',QTY);
  % need to index P.Rows into Ts
  RowInd=cell2mat(cellfun(@find,...
                          cellfun(@strcmp,P.Rows,repmat({Ts},1,length(P.Rows)), ...
                                  'UniformOutput',false),'UniformOutput',false));
  [Row,Col,Val]=find(P.Data{1});
  
  for i=1:length(P.Cols)
    [Rn(1:end).([P.Cols{i} QTY])]=deal(0);
  end
  for i=1:length(Val)
    Rn(RowInd(Row(i))).([P.Cols{Col(i)} QTY])=Val(i);
  end
  TQTY=strcat(T,QTY);
else
  TQTY={};
end
%  G, Ig, It, Im, O, Ox, D, f, RC, {T}
Rn=select(Rn,{'TSDF_EPA_ID',['G' QTY],['Ig' QTY],['Im' QTY],['It' QTY],...
              ['O' QTY],['Ox' QTY],['D' QTY],'f',[RC QTY],TQTY{:}});

