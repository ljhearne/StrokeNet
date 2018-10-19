clearvars
close all
%-------------------------------------------------------
% let's pretend we are mid script and we need some data
load testResults.mat
labels(9) = [];
thresh = 2000;
%-------------------------------------------------------

%re-interpret label indicies by hemisphere
netN = length(labels);
labels2 = flipud(labels);
newlabels = [labels;labels2];
for i = 1:netN 
    newlabels{i} = horzcat(newlabels{i},'_right');
    newlabels{i+netN }...
        = horzcat(newlabels{i+netN },'_left');
end


idx = netN + fliplr(1:netN);
for i = 1:size(COG,1)
    if COG(i,1) < 0
        newYeo8Index(i) = idx(Yeo8Index(i));
    else
        newYeo8Index(i) = Yeo8Index(i);
    end
end
labels = newlabels;
Yeo8Index = newYeo8Index;

% sort COG and Yeo8Index by new order
[~,idx] = sort(Yeo8Index);
Yeo8Index = Yeo8Index(idx);
COG = COG(idx,:);
    
% generate inner hierarchy
from = repmat({'origin'},size(labels));
to = labels;
T = table(from,to);
writetable(T,'H1.csv');
clearvars to from T

% generate outer hierarchy (node level)
deg = sum(abs(MAT)+abs(MAT'));
T = table(deg);
writetable(T,'deg.csv');

for i = 1:size(COG,1)
    from{i,1} = labels(Yeo8Index(i));
    to{i,1} = horzcat('node_',num2str(i));
    %value(i,1) = deg(i);
end
T = table(from,to);
writetable(T,'H2.csv');
clearvars to from T value

% generate matrix file (edge level)
newMAT = zeros(size(MAT));
MATthresh = abs(MAT);
tmp = sort(MATthresh(:),'descend');
MATthresh = MATthresh >= tmp(thresh);
newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
MAT = newMAT;
MATbin = MAT~=0;
[fromIDX,toIDX] = ind2sub(size(MATbin),find(MATbin));
for i = 1:size(toIDX,1)
    from{i,1} = horzcat('node_',num2str(fromIDX(i)));
    to{i,1} = horzcat('node_',num2str(toIDX(i)));
    value(i,1) = MAT(fromIDX(i),toIDX(i));
end
T = table(from,to,value);
writetable(T,'MAT.csv');