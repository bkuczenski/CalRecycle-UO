function a=ifinput(string,default,opt)
% function a = ifinput(inputstring,default)
%
% This function allows the user to input a value in response to a prompt or press 'enter' to accept a default
% answer.  For example, the syntax
%
% a=ifinput('How Many Apples?',3)
%
% will produce the output:
%
% how many apples? [3]_
%
% and if the user presses enter, will assign the value 3 to a.  THe default value for the default value is 0.
%
% the syntax 
%
% a=ifinput('What is your name?','Brandon','s')
%
% will force the user input to string format.
%
% Written by Brandon Kuczenski for Kensington Labs
% 13 September 2001

if nargin<2 default=0; end

if nargin==3
    if isa(default,'double') default=num2str(default); end
    a=input([string ' [' default '] '],'s');
else a=input([string ' [' num2str(default) '] ']); end

if isempty(a)  a=default; end
