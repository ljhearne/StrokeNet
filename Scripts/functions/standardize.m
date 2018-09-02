function X2 = standardize(X)
%standardize 
M = mean(X);
SD = std(X);

for i = 1:size(X,2)
    X2(:,i) = X(:,i)-M(i);
    X2(:,i) = X2(:,i)/SD(i);
end
end

