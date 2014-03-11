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

if length(ref)<10
  ind=find(strcmp(key,ref));
  if isempty(ind)
      [~,d]=sort([ref(:); key]);
      ind=find(d==length(d))-1;
  end
  return
end
debug=false;
if nargin==3 
  debug=true; 
  fprintf('%10s %10s %8s %s\n','siz','ind','diff(d)',key)
end

L=length(ref);siz=L;ind=0;d=1;
while 1
  siz=ceil(siz/2);
  ind=max([1,min([ind+d*siz,L])]);
  r=ref{ind};
  try 
    if strcmp(['a' key],['a' r]) break; end % 'a' to avoid '' == '' fail
  catch
    keyboard
  end
  [~,new_d]=sort({r;key});
  new_d=diff(new_d);
  if debug fprintf('%10g %10g %8d %s\n',siz,ind,new_d,r); end
  % break when: siz==1 and d and new_d have opposite signs
  if siz*d*new_d==-1 || (siz==1 & ind==L) || (new_d==-1 & ind==1)
      if new_d==-1
          ind=ind-1;
      end
      break
  end
  d=new_d;
end
if debug fprintf('%10g %10g %8d %s final\n',siz,ind,d,ref{ind}); end


