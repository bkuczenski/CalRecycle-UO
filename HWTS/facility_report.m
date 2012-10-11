function R=facility_report(EPAID,wc)
%function R=facility_report(EPAID,wc)
% runs through 2006-2010, building an output table for a given EPAID.

global Facilities

years=1993:2010;

wcs=num2str(wc);

[TSDF,Tx]=do_year(years(1),EPAID,wcs);
for i=2:length(years)
  [ta,txa]=do_year(years(i),EPAID,wcs);
  try
  TSDF=[TSDF ta];
  catch
    keyboard
  end
  Tx=[Tx txa];

end
%

% crop to list of method codes
MC=accum(TSDF,'ddmddd');
MC={MC.METH_CODE}; % list
m=strcat([wcs '_'],MC);

% output structure has rows: total received; fate by method code; total
% generated. 


R=struct('Indicator',{...
    [wcs '_Received'],...
    m{:},...
    [wcs '_Generated']});


for i=1:length(years)

  myyear=filter(TSDF,'year',{@eq},years(i));
  if ~isempty(myyear)
    a=accum(myyear,'dddadd');
    FN=fieldnames(a);
    mydata{1}=a.(FN{1});
    
    for j=1:length(MC)
      if isempty(MC{j})
        a=accum(filter(myyear,'METH_CODE',{@isempty},''),'ddmadd');
      else
        a=accum(filter(myyear,'METH_CODE',{@strcmp},MC{j}),'ddmadd');
      end
      if isempty(a)
        mydata{1+j}=0;
      else
        FN=fieldnames(a);
        mydata{1+j}=a.(FN{2});
      end
    end

    if isempty(Tx)
      mydata{length(R)}=0;
    else
      myyear_tx=filter(Tx,'year',{@eq},years(i));
      
      a=accum(myyear_tx,'dddddad');
      if isempty(a)
        mydata{length(R)}=0;
      else
        FN=fieldnames(a);
        mydata{length(R)}=a.(FN{1});
      end
    end
    
    [R.(['D_' num2str(years(i))])]=mydata{:};
  end

end

showfile=['facility_' EPAID '_' wcs '.csv'];
titleblock={...
    ['Facility Report for ' EPAID],...
    ['Waste Code ' wcs]};

F=Facilities(FACILITY_lookup(EPAID));
show(F,'',showfile,',',titleblock)

show(R,'',showfile,',')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [TSDF,Tx]=do_year(year,EPAID,wcs)

tanner_suffix=['_' num2str(year) '_' wcs];

tsdffile=['TSDF' tanner_suffix];
txfile=['TxSt' tanner_suffix];

cd(['Tanner' num2str(year)]);
load(tsdffile)
eval(['TT=' tsdffile ';'])
TSDF=filter(TT,'TSDF_BESTMATCH',{@regexp},EPAID);
load(txfile)
eval(['TX=' txfile ';'])
Tx=filter(TX,'TSDF_BESTMATCH',{@regexp},EPAID);
if ~isempty(TSDF)
  [TSDF.year]=deal(year);
end
if ~isempty(Tx)
  [Tx.year]=deal(year);
end

cd('..')

    
function mysum=myaccum(S,year)
FN=fieldnames(a);
mysum=a.(FN{1});

