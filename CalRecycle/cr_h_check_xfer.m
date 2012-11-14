function R=cr_h_check_xfer(H)
% searches through H to find EPAIDs in which fewer than 80% of records match the
% pattern where grand total = total transfered, and grand total > 0
%
% result is a structure with fields:
% EPAID
% NumRecords (where received > 0)
% NumEqual (received = transfered)
% NumNull (transfered = 0)
% TotalRcvd
% TotalTxfr

H=filter(H,'GrandTotalGallons',{@gt},0);

Elist=accum(H,'dddm');

for i=1:length(Elist)
  H1=filter(H,'EPAIDNumber',{@strcmp},Elist(i).EPAIDNumber);
%  keyboard
  HG=[H1(:).GrandTotalGallons];
  HX=[H1(:).TotalTransferedGallons];
  R{i,1}=Elist(i).EPAIDNumber;
  R{i,2}=length(H1);
  R{i,3}=sum(HG==HX);
  R{i,4}=sum(HX==0);
  R{i,5}=nearness(HG,HX);
  R{i,6}=sum(HG);
  R{i,7}=sum(HX);
  % scoring: 100 = perfect match
  score=(R{i,3}+0.5*R{i,4})*100/R{i,2};
  score=score+(100-score)*R{i,5};
  R{i,8}=round(score);
  if mod(i,10)==0 disp(['Completed ' num2str(i) ' IDs']); end
end

R=cell2struct(R,{'EPAID','NumRecords','NumEqual','NumNull','Nearness','TotalRcvd', ...
                 'TotalTxfr','Score'},2);

R=sort(R,'Score','descend');

function N=nearness(a,b)
% compares numerical vectors a and b on a string distance basis and comes up with a
% 0-1 score of 'nearness' based on the cumulative number of digits that must change.

x=find(a~=b & b>0);

cum=0;
err=0;

for j=1:length(x)
  d=strdist(num2str(a(x(j))),num2str(b(x(j))));
  L=max([length(num2str(a(x(j)))),length(num2str(b(x(j))))]);
  cum=cum+L;
  err=err+d;
end
N=(cum-err)/max([1,cum]);
