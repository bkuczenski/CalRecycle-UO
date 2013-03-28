function S=uo_exports(year,varargin)

if length(year)>1
  for i=1:length(year)
    S(i)=uo_exports(year(i),varargin{:});
  end
  return
end

if nargin>1
  fig=true;
else
  fig=false;
end

global MD GEO_REGION

yy=num2str(year);

Q=MD.(['Q_' yy '_221']);
[~,isexport]=filter(Q,{'GEN_EPA_ID','TSDF_EPA_ID'},{@regexp},{GEO_REGION},{0,1});
Qx=Q(isexport(:,end));

Qx=uo_distance(Qx);

S.Year=year;
S.Export_Count=length(Qx);
S.Export_Total_gal=sum([Qx.GAL]);
S.Export_uniq_gen=length(unique({Qx.GEN_EPA_ID}));
S.Export_uniq_dest=length(unique({Qx.TSDF_EPA_ID}));



bins=[0 1 10 100 500 1500 4000 8500 100000 inf ];

[count,binlist]=histc([Qx.GAL],bins);
S.Zero_gal=length(filter(Qx,'GAL',{@eq},0));

keyboard

if fig
  f=figure;
end
for i=1:length(count)-1
  S.(['Count_' num2str(bins(i)) '_' num2str(bins(i+1)) '_gal'])=count(i);
  MyDist=[Qx(find(binlist==i)).DISTANCE];
  MyDist(isnan(MyDist))=[];
  S.(['AvgDist_' num2str(bins(i)) '_' num2str(bins(i+1)) '_km'])=...
      mean(MyDist);
  if fig
    subplot(1,length(count)-1,i)
    hist(MyDist)
    if i==1
      ylabel('count')
    end
    title([yy ' ' num2str(bins(i)) '-' num2str(bins(i+1)) ' km'])
  end
end
if fig
  set(f,'Position',[  96         794        1515         154])
end
