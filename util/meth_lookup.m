function S=meth_lookup(S,varargin)
% function S=meth_lookup(S)
%
% Looks up METH_CODE from the supplied structure into the Tanner Methods table.
%
% function S=meth_lookup(S,alt_name)
%
% Looks up in the supplied alternative field instead of METH_CODE.
% 
% vlookup optional args are also handled.

args={};
keycol='METH_CODE';


while ~isempty(varargin)
  if ischar(varargin{1})
    switch varargin{1}(1:3)
      case {'inp','ine','str','old','bla','zer'}
        args=[args varargin(1)];
      otherwise
        keycol=varargin{1};
    end
  else
    disp('Don''t understand argument:')
    disp(varargin{1})
    keyboard
  end
  varargin(1)=[];
end

load Tanner
S=vlookup(S,keycol,Methods,'METH_CODE','METH_DESC',args{:});
