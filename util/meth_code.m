function D=meth_code(C,Desc)
% function meth_code(Code,Desc)
%
% Adds a new method code to the Tanner method code table in Tanner.mat
% C should be the code (string); Desc should be the CODE_DESC.  CODE_VALUE_DESC is
% always blank for new codes.

P=pwd;
if nargin<1
  % display all method codes
  S=load('Tanner.mat');
  show(select(S.Methods,{'METH_CODE','METH_DESC'}))
  return
end

if nargin<2 Desc=''; end

if iscell(C)
  if iscell(Desc) & size(Desc)==size(C)
    for i=1:length(C)
      meth_code(C{i},Desc{i});
    end
  else
    error('Code and Desc cell arrays must be the same length')
  end
else
  if ~ischar(C)
    C=char(C);
  end
  if ~ischar(Desc)
    Desc=char(Desc);
  end
  
  c=which('Tanner.mat');
  c=c(1:max(find(c=='/'|c=='\')));

  cd(c)
  
  S=load('Tanner.mat');
  f=find(strcmp({S.Methods(:).METH_CODE},C));
  if ~isempty(f)
    if isempty(Desc)
      D=S.Methods(f).METH_DESC;
      disp([S.Methods(f).METH_CODE ': ' D]);
      cd(P)      
      return;
    end
    disp([S.Methods(f).METH_CODE ' exists: ' S.Methods(f).METH_DESC]);
    s=lower(ifinput(['Really re-name to ' Desc ' ? '],'no','s'))
    if s=='y' | strcmp(s,'yes')
      S.Methods(f).METH_DESC=Desc;
      disp([S.Methods(f).METH_CODE ' renamed: ' S.Methods(f).METH_DESC ]);
      save('Tanner.mat','-struct','S');
    else
      disp([S.Methods(f).METH_CODE ' NOT renamed.'])
    end
  else
    if isempty(Desc)
      disp(['No existing method code ' C]);
      cd(P)      
      return
    end
    k=struct('METH_CODE',C,'CODE_VALUE_DESC','NA','METH_DESC',Desc);
    S.Methods(end+1)=k;
    disp([S.Methods(end).METH_CODE ': ' S.Methods(end).METH_DESC ' added']);
    save('Tanner.mat','-struct','S');
  end
end

cd(P)