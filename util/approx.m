function C=approx(A,B,tol)
% function C=approx(A,B,tol)
% Like eq, but allows for small variation.  approx(A,B,tol) returns true if
% abs(A-B)./A<tol.  Default tol is 1e-5.
if nargin<3 ; tol=1e-5; end

C=(abs(A-B)./A)<tol;
