function D=uo_data(varargin)
% function D=uo_data(opt)
%
% Generate indicators from uo data.  Select with opt.
%  1 or 'MD' - MD_221 and MD_222_223
%  2 or 'CR' - CR
%  3 or 'Freight' - Freight
%
% function D=uo_data(opt,DB)
%
% If the necessary source data is already in the calling workspace, pass it as
% argument.  If no argument is supplied, the proper data is loaded or generated
% depending on the value of 'opt'.
%
% Data are returned as substructures to the output structure D.  Each field of D is
% an indicator family, like 'CR', dependent on opt.  It contains structures with at
% least two fields each: Year, Value.  
%
% function D=uo_data(D,...) will work more cleanly on an existing D.  opt can also
% be one of the following:
%
%  'publish' - print to 
%
% D.(optname).(metadata)
% D.(optname).(indicator).{'Year','Value'}
%
% indicator

opt=varargin{1};
if nargin==2
DB=varargin{2};
end

switch opt
  case 1
    % *****************************************************************
    % Collection & Processing Inflows from Manifest data - 221
    % *****************************************************************
    if nargin<2
      load Node;
      DB=Node;
    end

    optname='MD_221';
    
    metadata={'Units','GAL','years',[2004 2005 2007:2011]};
    indicator={'TotalCollected',...
               'Consolidated',...
               'TotalTransferred',...
               'ExportedFromCA',...
               'TotalDisposed'};
    D=struct(optname,cell2struct(repmat({[]},1,length(indicator)),indicator,2));
    D.(optname)=union(D.(optname),struct(metadata{:}));

    y=D.(optname).years;

    for i=1:length(y)
      nn=['Rn_' num2str(y(i)) '_221'];
      
      Da=accum(select(DB.(nn),{'GGAL','IgGAL','OGAL','OxGAL','DGAL'}),'a','');
      DExCA=accum(select(filter(DB.(nn),'TSDF_EPA_ID',{@regexp},'^CA',1),...
                         {'GGAL','IgGAL','OGAL','OxGAL','DGAL'}),'a','');
      
      D.(optname)=appendval(D.(optname),'TotalCollected',y(i),Da.GGAL+Da.IgGAL);
      D.(optname)=appendval(D.(optname),'Consolidated',y(i),Da.GGAL);
      D.(optname)=appendval(D.(optname),'TotalTransferred',y(i),Da.OGAL+Da.OxGAL);
      D.(optname)=appendval(D.(optname),'ExportedFromCA',y(i),DExCA.DGAL);
      D.(optname)=appendval(D.(optname),'TotalDisposed',y(i),Da.DGAL);
    end
    D.(optname)=createtbl(D.(optname),indicator);
    
    % *****************************************************************
    % Collection & Processing Inflows from Manifest data - 222+223
    % *****************************************************************
    optname='MD_222_223';
        
    D.(optname)=cell2struct(repmat({[]},1,length(indicator)),indicator,2);
    D.(optname)=union(D.(optname),struct(metadata{:}));
    
    for i=1:length(y)
      for j=1:2
        nN{j}=['Rn_' num2str(y(i)) '_22' num2str(j+1)];
      end
      Dn=stack(DB.(nN{1}),DB.(nN{2}));
      
      Da=accum(select(Dn,{'GGAL','IgGAL','OGAL','OxGAL','DGAL'}),'a','');
      DExCA=accum(select(filter(Dn,'TSDF_EPA_ID',{@regexp},'^CA',1),...
                         {'GGAL','IgGAL','OGAL','OxGAL','DGAL'}),'a','');
      
      D.(optname)=appendval(D.(optname),'TotalCollected',y(i),Da.GGAL+Da.IgGAL);
      D.(optname)=appendval(D.(optname),'Consolidated',y(i),Da.GGAL);
      D.(optname)=appendval(D.(optname),'TotalTransferred',y(i),Da.OGAL+Da.OxGAL);
      D.(optname)=appendval(D.(optname),'ExportedFromCA',y(i),DExCA.DGAL);
      D.(optname)=appendval(D.(optname),'TotalDisposed',y(i),Da.DGAL);
    end
    
      D.(optname)=createtbl(D.(optname),indicator);
      
  case 2
    % *****************************************************************
    % Collection & Processing Inflows from CalRecycle data
    % *****************************************************************
    if nargin<2
      DB=uo_load('CR','../CalRecycleData/');
    end
    optname='CR';

    metadata={'Units','GAL','years',[2004:2011]};
    indicator={'LubSalesCA',...
               'IndSalesCA',...
               'LubeCollected',...
               'IndCollected',...
               'LubeTransferred',...
               'IndTransferred',...
               'LubeProcessedRpt',...
               'IndProcessedRpt',...
               'LubeProcessedRptExCA',...
               'IndProcessedRptExCA',...
               'LubeProcessedCorr',...
               'IndProcessedCorr'};
    D=struct(optname,cell2struct(repmat({[]},1,length(indicator)),indicator,2));
    D.(optname)=union(D.(optname),struct(metadata{:}));
    
    y=D.(optname).years;

    H=accum(select(DB.CR_Hauler,...
                   {'Year','EPAIDNumber','LubTotalGallons','IndTotalGallons'}),...
            'mm','');
    
    P=accum(select(DB.CR_Proc,...
                   {'Year','EPAIDNumber','GrandTotalOilReceivedGallons', ...
                    'RecycledOilTotalGallons','ResidualMaterialTotalGallons',...
                    'TotalIndGallons'}),'mm','');
      
    S=DB.CR_Sales;
    
    T=accum(DB.CR_Txfr,'dddmaaa','')

    
    for i=1:length(y)
      Sy=filter(S,'Year',{@eq},y(i));
      D.(optname)=appendval(D.(optname),'LubSalesCA',y(i),floor(1e6*Sy.LubCons));
      D.(optname)=appendval(D.(optname),'IndSalesCA',y(i),floor(1e6*Sy.IndCons));

      Hy=accum(filter(H,'Year',{@eq},y(i)),'mdaa','');

      D.(optname)=appendval(D.(optname),'LubeCollected',y(i),Hy.LubTotalGallons);
      D.(optname)=appendval(D.(optname),'IndCollected',y(i),Hy.IndTotalGallons);
      
      Py=accum(filter(P,'Year',{@eq},y(i)),'mdaaaa','');
      D.(optname)=appendval(D.(optname),'LubeProcessedRpt',y(i),...
                            Py.GrandTotalOilReceivedGallons- Py.TotalIndGallons);
      D.(optname)=appendval(D.(optname),'IndProcessedRpt',y(i),...
                            Py.TotalIndGallons);

      Ty=filter(T,'Year',{@eq},y(i));
      D.(optname)=appendval(D.(optname),'LubeTransferred',y(i),Ty.LubeOil);
      D.(optname)=appendval(D.(optname),'IndTransferred',y(i),Ty.IndOil);
      
      Pyx=accum(filter(P,{'Year','EPAIDNumber'},{@eq,@regexp},{y(i),'^CA'},{0,1}),'mdaaaa','');
      D.(optname)=appendval(D.(optname),'LubeProcessedRptExCA',y(i),...
                            Pyx.GrandTotalOilReceivedGallons- Pyx.TotalIndGallons);
      D.(optname)=appendval(D.(optname),'IndProcessedRptExCA',y(i),...
                            Pyx.TotalIndGallons);
      
      Pyy=accum(filter(P,{'Year','RecycledOilTotalGallons'},{@eq},{y(i),0},{0,1}),...
                'm','');
      D.(optname)=appendval(D.(optname),'LubeProcessedCorr',y(i),...
                            Pyy.GrandTotalOilReceivedGallons- Pyy.TotalIndGallons);
      D.(optname)=appendval(D.(optname),'IndProcessedCorr',y(i),...
                            Pyy.TotalIndGallons);

      D.(optname)=createtbl(D.(optname),indicator);

      
    end

  case 3
    % *****************************************************************
    % Manifest Distance and freight transport
    % *****************************************************************
    
    
  otherwise
    error(['Unsolved option ' num2str(opt)])
end

function G=appendval(G,ind,year,value);
if ~isfield(G,ind)
  G.(ind)=struct;
end
k=length(G.(ind));
G.(ind)(k+1).Year=year;
G.(ind)(k+1).Value=value;

function G=createtbl(G,ind)
G.Table=G.(ind{1});
G.Table=mvfield(G.Table,'Value',ind{1});
for k=2:length(ind)
  G.Table=vlookup(G.Table,'Year',G.(ind{k}),'Year','Value','zer');
  G.Table=mvfield(G.Table,'Value',ind{k});
end
