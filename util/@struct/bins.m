function [S,Centers,CenterNames]=bins(S,Field,Bins,varargin)
% function S=bins(S,Field,Bins)
% 
% Replaces a numerical data column with a partitioning of the data value into
% specified bins.  Useful as a prelude to accum.
%
% Bins specifies either the number of bins (scalar) or the edges between the bins
% (as in histc, vector).  The field value will be replaced with the center of the
% bin to which it belongs. 
%
% [S,B]=bins(S,Field,Bins) returs the bin centers in B. 
%
% bins(...,'text') will return concise bin names (text) in place of numeric center
% values.
%
% [S,B,C]=bins(S,Field,Bins,'text') returs the bin centers in B and a cell array
% containing center names in C.
%
% bins(S,Field,Bins,NewField) will preserve the original data in 'Field' and
% supply the bin center in 'NewField'.

use_centernames=false;

if nargin<4
  NewField=Field;
else
  while ~isempty(varargin)
    switch varargin{1}
      case 'text'
        use_centernames=true;
      otherwise
        NewField=varargin{1};
    end
    varargin=varargin(2:end);
  end
end

[Sm,I]=sort([S.(Field)],'ascend');
[~,Ir]=sort(I);
M=~isnan(Sm) & ~isinf(Sm);
%Sm=Sm(M);

if isscalar(Bins)
  % reports the desired number of bins; assume equally spaced
  binsize=(1+Sm(max(find(M)))-Sm(min(find(M))))/Bins;
  Bins=Sm(min(find(M))):binsize:Sm(max(find(M)))+1; % replace scalar with bin edges
else
  % assume bins already specified; compute smallest binsize
  binsize=min(diff(Bins));
end

Centers=mean([Bins(1:end-1);Bins(2:end)]);

[N,BIN]=histc(Sm,Bins);

if use_centernames
  % keep the center names just precise enough- 1 OM finer than binsize
  scale=10^floor(log10(binsize)-1);
  CenterNames=scale*floor(Centers/scale);
  CenterNames(find(abs(Centers)<binsize))=floor(Centers(find(abs(Centers)< ...
                                                    binsize)));
  precis=1+floor(log10(max(abs(Centers)))); % necessary printf precision
  for i=1:length(CenterNames)
    CenterTitle{i}=sprintf('B%0.*i',precis,CenterNames(i));
  end
  try
  NewFieldVal=CenterTitle(BIN(Ir(M(Ir))));
  catch
    disp('NewFieldVal')
    keyboard
  end
  [S(~M(Ir)).(NewField)]=deal('NaN');
else
  try
  NewFieldVal=num2cell(Centers(BIN(Ir(M(Ir)))));
  catch
    disp('NewFieldVal')
    keyboard
  end
  
  [S(~M(Ir)).(NewField)]=deal(NaN);
end
try
  [S(M(Ir)).(NewField)]=deal(NewFieldVal{:});
catch
  disp('assignment')
  keyboard
end
