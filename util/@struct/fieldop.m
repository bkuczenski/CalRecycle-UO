function S=fieldop(S,target,expr)
% function S=fieldop(S,target,expr)
% 
% Perform an operation on a field or fields of a structure array, storing the
% result in the field named 'target'.  This could be a new or existing field.
% in other words, 'target' = eval('expr')
%
% S is any structure array.  
%
% 'expr' should be a matlab expression, referring to fields in S using the hash
% symbol, followed by the field name, followed by a non-word character like a space,
% for example '#FieldName.'  The function assumes fields will evaluate as numeric
% arrays (square brackets & num2cell are used).
%
% The expression should be written to accommodate horizontal (e.g. 1 x length(S) )
% arrays.
%
% Example: if a is an nx1 structure with fields 'Bort' and 'Slimy', then 
% fieldop(a,'Bort','#Bort + #Slimy') will set Bort equal to the sum of Bort and
% Slimy for each of the n elements of a.

Fs=strrep(regexp(expr,'#\w+','match'),'#','');
for k=1:length(Fs)
  % deal with zeros
  [S(cellfun(@isempty,{S.(Fs{k})})).(Fs{k})]=deal(NaN); % change!!!!!
  eval([Fs{k} '= [S.(Fs{k})];']);
end
T=eval(strrep(expr,'#',''));
if ~iscell(T)
  T=num2cell(T);
end

[S.(target)]=deal(T{:});

