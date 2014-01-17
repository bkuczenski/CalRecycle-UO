function ind=bisect_find(key,ref,argin);
% function ind=bisect_find(key,ref);
%
% key is a string and ref is a sorted cell array of strings.  Finds the index into
% ref that is equal to key, if it exists.  If not, finds the highest index that is
% lower than the key.

% nomenclature:
%  siz = size of bisection region
%  ind = current pointer, starts at 0
%  d   = direction of next bisection (1 or -1)

if length(ref)<4
  ind=find(strcmp(key,ref));
  if isempty(ind)
      [~,d]=sort([ref(:); key]);
      ind=d(end)-1;
  end
  return
end
debug=false;
if nargin==3 
  debug=true; 
  fprintf('%10s %10s %8s \n','siz','ind','diff(d)')
end
siz=length(ref)/2-0.5;ind=1;d=1;
while siz>0.5
  ind=max([ind+d*siz,1]);
  siz=siz/2;
  r=ref{round(ind)};
  try 
    if ['a' key]==['a' r] break; end % 'a' to avoid '' == '' fail
  end
  [~,d]=sort({r;key});
  if debug fprintf('%10g %10g %8d\n',siz,ind,diff(d)); end
  d=diff(d);
  if siz<=0.5
    ind=ind+1.01*d*siz; % this is to deal with small-number difficulties
  end
end
ind=max([round(ind),1]);
if debug fprintf('%10g %10g %8d final\n',siz,ind,diff(d)); end


