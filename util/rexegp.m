function S=rexegp(pat,str,varargin)
% function S=rexegp(pat,str,varargin)
% reverses the order of inputs to regexp.
% n.b. name is obtained by twice transposing adjacent letters of 'regexp'
S=regexp(str,pat,varargin{:});

