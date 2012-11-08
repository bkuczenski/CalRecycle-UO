function [Ds,M]=filter(D,Field,Test,Pattern,Inv)
% Ds=filter(D,Field,Test,Pattern)
% 
% D is a table structure.  'Field', 'Test',
% and 'Pattern'.  'Field' can be either a numeric index (into the array returned by
% fieldnames.m) or a field name.  'Test' can be any Matlab relational operator, given
% as a function handle (e.g. @lt rather than '<').  The test function is evaluated
% using feval(Test,D.(Field),Pattern).  The result must be both nonempty and
% non-false for the field to pass the filter.
%
% If 'Pattern' is empty, 'Test' is assumed to be a unary operator (like @isempty).
%
% For multiple and-wise filters, use cell arrays for Field, Test, and Pattern.
%
% Ds=filter(D,Field,Test,Pattern,Inv)
% An optional field 'Inv' with a nonzero value will cause the result of the test
% to be inverted.
%
% Ds=filter(D,filt)
% 
% filt is a structure array with fields 'Field', 'Test', 'Pattern', and optional
% 'Inv'.
%
% Optional second argument returns a logical array of length(D) by length(filt)
% reporting the results of the filter comparisons.


Ds=[];

FN=fieldnames(D);

if nargin==2
  filt=Field;
  if ~isfield(filt,'Inv') filt.Inv=0; end
else
  if nargin<5 Inv=0; end
  filt=struct('Field',Field,'Test',Test,'Pattern',Pattern,'Inv',Inv);
end

M=logical(zeros(length(D),length(filt)));

for i=1:length(D)
  filt_pass=1;
  for f=1:length(filt)
    if isnumeric(filt(f).Field)
      mydata=D(i).(FN{filt(f).Field});
    else
      mydata=D(i).(filt(f).Field);
    end
    if isnan(mydata)
      result=false;
    elseif isempty(filt(f).Pattern)
      try
        result=feval(filt(f).Test,mydata);
      catch
        disp('trycatch: filter feval empty pattern')
        keyboard
      end
    else
      try
        result=feval(filt(f).Test,mydata,filt(f).Pattern);
      catch 
        ll=lasterr
        keyboard
      end
    end
    if filt(f).Inv
      if islogical(result)
        result=~result;
      else
        if isempty(result)
          result=1;
        else
          result=[];
        end
      end
    end
    % try
    %   isempty(result) | ~result;
    % catch
    %   keyboard
    % end
    if  isempty(result) | ~result
      filt_pass=0;
      break;
    end
    M(i,f)=true;
  end
  if filt_pass
    if isempty(Ds)
      Ds=D(i);
    else
      Ds(end+1)=D(i);
    end
  end
end
Ds=Ds(:);

