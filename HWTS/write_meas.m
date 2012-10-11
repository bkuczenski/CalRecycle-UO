% script file to print Measurements to file

units={'Mgal','tonnes','tonnes'};
showfile='HWTS-measurements.csv';
delete(showfile);
scale=[1/3300 1 1];

for i=1:length(Measurements)
  FN=fieldnames(Measurements{i});
  NumYears=length(Measurements{i});
  [M(1:NumYears).Year]=deal(Measurements{i}(:).Year);
  for j=3:length(FN)
    prod=num2cell([Measurements{i}(:).(FN{j})].*scale(i));
    [M(:).(FN{j})]=prod{:};
  end
  M=rmfield(M,'Record_Count');
  show(sort(M,'Year','ascend'),'',showfile,',*',{
      'Material Flow Summary - Tanner Report Data',
      ['Waste Code ' num2str(Measurements{i}(1).WasteCode) '; years 1993-2011'],
      ['All units in ' units{i}]})
end

  
    