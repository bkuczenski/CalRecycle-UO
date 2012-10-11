function ind=bisect_find(key,ref);
% function ind=bisect_find(key,ref);
% finds the index into the sorted list ref where one would want to file key.
% line 17- changed < to <= 2012-10-05 debug

siz=length(ref)/2;ind=0;d=1;
while siz>0.5
  ind=max([ind+d*siz,1]);
  siz=siz/2;
  r=ref{floor(ind)};
  try key==r;
    if key==r   break; end
  end
  [~,d]=sort({r;key});
  %[ind diff(d)]
  d=diff(d);
  if siz<=0.5 & d>0
    ind=ind+1; 
  end
end
ind=max([floor(ind),1]);

    
