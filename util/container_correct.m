function S=container_correct(S,k)
% function S=container_correct(S)
% uses MethCoor to translate erroneous CONTAINER_TYPEs to correct ones.  Uses
% ContainerCorr in util directory.
%
% function S=meth_correct(S,field)
% applies correction to the named field (default CONTAINER_TYPE).
%
% Reads ContainerCorr fresh every time, so make live changes.

fprintf('Correcting container types on %s: ',inputname(1))
MC=read_dat('ContainerCorr',',');
if nargin>1
  field=k;
else
  field='CONTAINER_TYPE';
end

S=vlookup(S,field,MC,'IN','OUT','inplace');


