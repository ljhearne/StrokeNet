function [X,Y,L]=CA(Q)

% do correspondence analysis
% AUTHOR: Ikko Kimura, 2015/06/12, Osaka University
% 2016/03/21 fixed some bugs..         Ikko Kimura, Osaka University
% 2016/04/09 make the output pretty!!  Ikko Kimura, Osaka University

% [X Y L]=CA(Q)
% 
% Q: matrix (subject*keyword)
%
% X: for subject plot
% Y: for keyword plot
% L: explained variance

m=min(size(Q,1),size(Q,2));
R=diag(sum(Q,2)); % sum of y (dimesion)
S=diag(sum(Q,1)); % sum of x (subject)
X=R^(-0.5)*Q*S^(-0.5); %  normalized matrix

if isnan(X)==1 % just in case...
    display('!!! CAN NOT CALCULATE THIS SORRY !!!')
    return
end

[U_ast,L,V_ast]=svd(X,0); 
U=R^(-0.5)*U_ast; % for subject plot 
V=S^(-0.5)*V_ast; % for dimension plot 

X=U(:,2:m);
Y=V(:,2:m);
lambda=diag(L);
lambda=(lambda(2:end)).^2;
L=lambda./sum(lambda);

end