% script file to do datagen
% really, this shouldn't be called 'Make' since it only makes one thing
% but oh well.




Years=2011:-1:1993;
WCs=221:223;

X141_done=19;
deblank_done=19;

% for i=1:length(Years)
%   if i>deblank_done
%     cd(['Tanner' num2str(Years(i))])
%     pwd
%     for j=1:length(WCs)
%       disp(['WC ' num2str(WCs(j)) ' for year ' num2str(Years(i))])
%       mdf=['MD_' num2str(Years(i)) '_' num2str(WCs(j)) ];
%       disp([' loading ' mdf '.mat'])
%       load([mdf '.mat'])
%       disp('Deblanking waste code')
%       eval([ mdf '=moddata(' mdf ...
%              ',''WASTE_STATE_CODE'',@(x)(num2str(str2num(x))))']);
%       disp([' loading ' mdf '.mat'])
%       save([mdf '.mat'],mdf)
%       clear(mdf)
%     end
%     deblank_done=max([deblank_done,i]);
%     cd('..')
%   end
% end

    
      


    

if exist('HWTS.mat','file') load HWTS; end
save HWTS_old Measurements Outputs

try
  homedir='/home/b/Dropbox/matlab/HWTS';
  cd(homedir)
catch
  homedir='c:\users\brandon\my dropbox\matlab\HWTS';
  cd(homedir)
end  

Meas={'STATEWIDE_GENERATED_TONS',
              'INSTATE_H141_TONS',
              'H141_SHORTFALL',
              'NetTons',
              'Record_Count',
              'Import',
              'Export'};

OutputRegions={'CA','Ex'};


manfiles={'TANNER2011.txt',%2011
          'Manifest.txt',%2010
          'MANIFEST.txt',%2009
          'tanner2008.txt',
          'TANNER2007.txt',
          'TANNER2006.txt',
          'tanner2005.txt',
          'tanner2004.txt',
          'tanner2003.txt',
          'tanner2002.txt',
          '2001_SUMMARY.txt',
          'tanner2000.txt',
          'tanner_1999.txt',
          'tanner_1998.txt',
          'tanner_1997.txt',
          'tanner_1996.txt',
          'tanner_1995.txt',
          'tanner_1994.txt',
          'tanner_1993.txt'         };

for i=6:6  % 1 = 2011; 19 = 1993
  cd(homedir)
  dirname=['Tanner' num2str(Years(i))];
  cd(dirname)
  pwd
  for j=1:3 %1:length(WCs)
    % cleanup and rebuild for X141
    if i>X141_done
      disp('Cleaning for X141')
      delete(['TxSt_' num2str(Years(i)) '_' num2str(WCs(j)) '.mat']);
    end
      

    
    disp(['################ RUNNING MDMFA FOR WC ' num2str(WCs(j)) ... 
          ' for ' num2str(Years(i)) ' #####'])
    R=mdmfa(manfiles{i},Years(i),WCs(j));
    % build results table
    Measurements{j}(i).WasteCode=WCs(j);
    Measurements{j}(i).Year=Years(i);
    Outputs{j}(i).Year=Years(i);
    for k=1:length(Meas)
      Measurements{j}(i).(Meas{k})=getfield(R,Meas{k});
    end
    for k=1:length(OutputRegions)
      ThisOut=getfield(R,['Outputs_' OutputRegions{k}]);
      ON=fieldnames(ThisOut);
      for kk=2:length(ON)
        Outputs{j}(i).([ON{kk} '_' OutputRegions{k}])=getfield(ThisOut,ON{kk});
      end
    end
  end
end

cd(homedir)

save HWTS Measurements Outputs
write_meas
