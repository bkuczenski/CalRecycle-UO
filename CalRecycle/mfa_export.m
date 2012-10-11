%% script file to generate TeX data file , in turn to plug into oil mfa figure.
%% This should be easy.  


tab_columns={'Var','Label','Style','A','B','C','D','E','F','G'};
% where year = 2003 + (A=1, B=2..)

if ~exist('CRData','var')
  load CRData
end

if 1
  years=2004:2010;

  for i=1:length(years)
    XData{i}=flatten(mfa_extract(CRData,years(i)));
    XData{i}=moddata(XData{i},'Key',@(x)(regexprep(x,'^\.','')));
    %XData{i}=moddata(XData{i},'Key',@(x)(tr(x,'0123456789_.','xabcdefghi')),'TeXKey');
    XData{i}=moddata(XData{i},'Key',@(x)(tr(x,'_.','')),'TeXKey');
  end

  xdk={};
  for i=1:6
    xdk1={XData{i}.TeXKey};
    xdk={xdk{:} xdk1{:}};
  end
  
  Queries=cell2struct(unique(xdk),'Query');
  
  show(Queries,'','CRValidQueries.txt','''')
end

Q=read_dat('CR-Queries.txt',',');
Q=mvfield(Q,'Query','TeXKey'); % query all fields

% move year first
f=find(strcmp({Q.TeXKey},'Year'));
Q=Q([f 1:f-1 f+1:end]);

[~,ms]=filter(Q,'Style',{@strcmp},'*s');  %indicates string metadata - we want to pull
                                            %these out

[~,md]=filter(Q,'Style',{@strcmp},'*d');  %indicates decimal metadata - we want to pull
                                            %these out

Sm=query_tex_dat(XData,'',{'Var','Label','Style'},Q(ms|md));
%Sd=query_tex_dat(XData,'FlowDataICF',{'Var','Label','Style'},Q(md));
S=query_tex_dat(XData,'',{'Var','Label','Style'},Q(~(ms|md)));

filename=['FlowDataICF_' datestr(now,'YYYY-mmm-DD') '.csv'];

target=2;

switch target
  case 0
    % now, generate the TeX files
    S=query_tex_dat(XData,'FlowDataICF',...
                    {'Var','Label','Style'},...
                    {'CRUnits','Units','*c';
                     'Year','','*c';
                     'CRSalesLub','Lubricants',                 'lub';
                     'CRSalesInd','Industrial Oils',            'ind';
                     'MDUOGenWCbba','221 Used Oil','';
                     'MDUOGenWCbbb','222 Oil-Water Separation Sludge','';
                     'MDUOGenWCbbb','223 Other Oil-containing waste','';
                     'CRHaulingLubTotal','Lubricants','lub';
                     'CRHaulingIndTotal','Industrial Oils','ind';
                     'CRHaulingCC','Collection Centers','cc';
                     'CRHaulingConsol','Consolidators','consol';
                     'CRHaulingInds','Industrial','ind';
                     'CRHaulingAgr','Agricultural','agr';
                     'MDHaulingTxStation','Hauling - Transfer Stations','';
                     'MDHaulingTxLosses','Losses - Transfer Stations','';
                     'MDGeogExports','Exports out of CA - DTSC','';
                     'CRProcessedExports','Exports out of CA - CR','';
                     'CRProcessedTotal','Total Oil Disposed - CR','';
                     'MDDispositionTotal','Total Oil Disposed - DTSC','';
                     'MDDispositionHxci','H039 Reuse or Recycling','';
                     'MDDispositionHacb','H132 Landfill or Surface Impoundment','';
                     'MDDispositionHace','H135 Discharge to POTW / NPDES','';
                     'MDDispositionHxdx','H040 Destructive Incineration','';
                     'MDDispositionHxex','H050 Energy Recovery, on-site','';
                     'MDDispositionHxfa','H061 Energy Recovery, off-site','';
                     'CRProductsBaseOil','Base Oil Generated - CR','';
                     'CRProductsLightFuels','Light Fuels Generated - CR','';
                     'CRProductsRFO','RFO Generated - CR','';
                     'CRProductsAsphalt','Asphalt Generated - CR','';
                     'CRProductsTotal','Total Products - CR','';
                     'MDProductsBaseOil','Base Oil Generated - MD','';
                     'MDProductsLightFuels','Light Fuels Generated - MD','';
                     'MDProductsRFO','RFO Generated - MD','';
                     'MDProductsAsphalt','Asphalt Generated - MD','';
                     'MDProductsTotal','Total Products - MD',''});
  case 1
    S=query_tex_dat(XData,'FlowDataICF',...
                    {'Var','Label','Style'},...
                    {'CRUnits','Units','*c';
                     'Year','','*c';
                     'CRSalesLub','Lubricants',                 'lub';
                     'CRSalesInd','Industrial Oils',            'ind';
                     'MDUOGenWC221','221 Used Oil','';
                     'MDUOGenWC222','222 Oil-Water Separation Sludge','';
                     'MDUOGenWC223','223 Other Oil-containing waste','';
                     'CRHaulingLubTotal','Lubricants','lub';
                     'CRHaulingIndTotal','Industrial Oils','ind';
                     'CRHaulingCC','Collection Centers','cc';
                     'CRHaulingConsol','Consolidators','consol';
                     'CRHaulingInds','Industrial','ind';
                     'CRHaulingAgr','Agricultural','agr';
                     'MDHaulingTxStation','Hauling - Transfer Stations','';
                     'MDHaulingTxLosses','Losses - Transfer Stations','';
                     'MDGeogExports','Exports out of CA - DTSC','';
                     'CRProcessedExports','Exports out of CA - CR','';
                     'CRProcessedTotal','Total Oil Disposed - CR','';
                     'MDDispositionTotal','Total Oil Disposed - DTSC','';
                     'MDDispositionH039','H039 Reuse or Recycling','';
                     'MDDispositionH132','H132 Landfill or Surface Impoundment','';
                     'MDDispositionH135','H135 Discharge to POTW / NPDES','';
                     'MDDispositionH040','H040 Destructive Incineration','';
                     'MDDispositionH050','H050 Energy Recovery, on-site','';
                     'MDDispositionH061','H061 Energy Recovery, off-site','';
                     'CRProductsBaseOil','Base Oil Generated - CR','';
                     'CRProductsLightFuels','Light Fuels Generated - CR','';
                     'CRProductsRFO','RFO Generated - CR','';
                     'CRProductsAsphalt','Asphalt Generated - CR','';
                     'CRProductsTotal','Total Products - CR','';
                     'MDProductsBaseOil','Base Oil Generated - MD','';
                     'MDProductsLightFuels','Light Fuels Generated - MD','';
                     'MDProductsRFO','RFO Generated - MD','';
                     'MDProductsAsphalt','Asphalt Generated - MD','';
                     'MDProductsTotal','Total Products - MD',''});
    
    
  otherwise
    show(Sm,'',{filename,1,true},',*')
    show(S,'',{filename,2},',*')



%tab_rows={...%
% {'CR.Sales.Lub','LubSales','Lubricants','lub';
%           'CR.Sales.Ind','IndSales','Industrial Oils','ind';
%           'MD.UOGen.Total','Gen','Used Oil Generation','';
%           'MD.UOGen.WC_221','GenUO',
%           'MD.UOGen.WC_222','GenSS','222 Oil-Water Separation Sludge','';
%           'MD.UOGen.WC_223','GenOCW','223 Other Oil-containing Waste','';
%           'MD.Geog.WC_221_ex','ExpUO','221 - Exported','';
%           'MD.Geog.WC_222_ex','ExpSS','222 - Exported','';
%           'MD.Geog.WC_223_ex','ExpOCW','223 - Exported','';
%           'MD.Hauling.TxStation','Tx','Transfer Stations','';
%           'CR.Hauling.Lub.CC','CRLCC','Collection Centers','';               
%           'CR.Hauling.Lub.Ind','CRLInd','Industrial','';                      
%           'CR.Hauling.Lub.Mar','CRLMar','Marine','';                          
%           'CR.Hauling.Lub.Agr','CRLAgr','Agricultural','';                    
%           'CR.Hauling.Lub.Gov','CRLGov','Government','';                      
%           'CR.Hauling.Lub.Import','CRLImp','Import from out-of-state','';        
%           'CR.Hauling.Lub.Consol','CRLCons','Consolidated from other haulers','';
%           'CR.Hauling.Lub.Total','CRLH','Lube - Total Hauling','';              
%           'CR.Hauling.Ind.CC','CRICC','Collection Centers','';               
%           'CR.Hauling.Ind.Ind','CRIInd','Industrial','';                      
%           'CR.Hauling.Ind.Mar','CRIMar','Marine','';                          
%           'CR.Hauling.Ind.Agr','CRIAgr','Agricultural','';                    
%           'CR.Hauling.Ind.Gov','CRIGov','Government','';                      
%           'CR.Hauling.Ind.Import','CRIImp','Import from out-of-state','';        
%           'CR.Hauling.Ind.Consol','CRICons','Consolidated from other haulers','';
%           'CR.Hauling.Ind.Total','CRIH','Industrial Oil - Total Hauling','';              
%           'CR.Hauling.Total','CRH','Total Hauling','';
%           'CR.Processed.Exports','CRExp','CR Exported','';
%           'CR.Products.BaseOil','CRBO','CR Base Oil','';
%           'CR.Products.LightFuels','CRLF','CR Light Fuels','';
%           'CR.Products.RFO','CRRFO','CR RFO','';
%           'CR.Products.Asphalt','CRAsph','CR Asphalt','';
%           'CR.Products.Total','CRProd','CR Total Products','';
%           'MD.Products.BaseOil','MDBO','DTSC Base Oil','';
%           'MD.Products.LightFuels','MDLF','DTSC Light Fuels','';
%           'MD.Products.RFO','MDRFO','DTSC RFO','';
%           'MD.Products.Asphalt','MDAsph','DTSC Asphalt','';
%           'MD.Products.Total','MDProd','DTSC Total Products','';
%           'MD.Disposition.Total','Disp','Total Oil Disposed','';
%           'MD.Disposition.H039','Recyc','H039 Reuse or Recycling','';
%           'MD.Disposition.H061','EROff','H061 Energy Recovery, off-site','';
%           'MD.Disposition.H050','EROn','H050 Energy Recovery, on-site','';
%           'MD.Disposition.H135','Water','H135 Discharge to POTW / NPDES','';
%           'MD.Disposition.H132','Land','H132 Landfill or Surface Impoundment','';
%           'MD.Disposition.H040','Incin','H040 Destructive Incineration','';
%           }';
end