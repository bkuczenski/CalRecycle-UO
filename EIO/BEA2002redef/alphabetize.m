function A=alphabetize(A,tok)
% inserts tok in the proper position in ascending sequence in A.  for now, works
% only with the first column.
if isempty(A)
  A=tok;
else
  [m,l]=ismember(A(:,1),tok(1));
  if ~any(m)
    G=0;
    for i=size(A,1):-1:1
      switch strlexcmp(A{i,1},tok{1})
        case 1 % expected normal case: current entry > prospective entry
               % do nothing
          G=1;
        case -1 % crossover case
          if G==0 A=[A;tok];
          else
            A=[A(1:i,:);tok;A(i+1:end,:)];
          end
          break
        otherwise % 0 case
          break
      end
    end
  end
end

