function y=break_string(s,b)
% function y=break_string(s,b)
% breaks input string s into chunks whose lengths are given by the elements of
% b. Extra characters leftover at the end are dropped. 
%
% Example: 
%
% break_string('I seem to be having tremendous difficulty with my lifestyle',[4 1
% 5 22])
%
% returns a 4x1 cell array:
%
% ans = 
%   'I se'    'e'    'm to '    'be having tremendous d'
%
% Cody problem 967. Mon 10-01 23:50:48
% reference solution has size 59 :(
% first alternate solution has size 40.

% if prod(size(b))==1
%   y={s(1:b)};
% else
%   y=[{s(1:b(1))} break_string(s(b(1)+1:end),b(2:end))];
% end

for i=1:length(b)
  y{i}=s(1:b(i));
  s=s(b(i)+1:end);
end
