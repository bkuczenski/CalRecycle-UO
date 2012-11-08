function S=meth_correct(S,k)
% function S=meth_correct(S)
% uses MethCoor to translate erroneous METH_CODEs to modern, H### codes.
%
% function S=meth_correct(S,1)
% also maps old X## codes to new H### codes using Methods_old
%
% This function assumes the field to be corrected is called 'METH_CODE'
%
% Reads MethCorr fresh every time, so make live changes.

fprintf('Correcting method codes on %s: ',inputname(1))
MC=read_dat('MethCorr',',');
S=vlookup(S,'METH_CODE',MC,'IN','OUT','inplace');

if nargin>1
  switch k
    case 1
      load Tanner
      S=vlookup(S,'METH_CODE',Methods_old,'METH_CODE_OLD','METH_CODE_NEW', ...
                'inplace');
    otherwise
      disp('Don''t know what to do with that arg.')
  end
end

