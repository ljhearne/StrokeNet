function ConnectogramR(MAT,COG,net,labels,out)
%ConnectogramR(MAT,COG,net,labels,out)
    %function that writes a bunch of .csv files that are read by an Rscript
    %(EdgeBundle.R) that creates a connectogram diagram. Coding is specific
    %to the current dataset/project due to my subpar R coding skills.

netN = length(labels);

% generate inner hierarchy
from = repmat({'origin'},size(labels));
to = labels;
T = table(from,to);
INatt = [out,'_Bundle1.csv'];
writetable(T,INatt);
clearvars to from T

% generate outer hierarchy (node level)
deg = sum(abs(MAT)+abs(MAT'));
T = table(deg);
INdeg = [out,'_deg.csv'];
writetable(T,INdeg);

for i = 1:size(COG,1)
    from{i,1} = labels(net(i));
    to{i,1} = horzcat('node_',num2str(i));
    %value(i,1) = deg(i);
end
T = table(from,to);
INatt2 = [out,'_Bundle2.csv'];
writetable(T,INatt2);
clearvars to from T value

% generate matrix file (edge level)
MATbin = MAT~=0;
[fromIDX,toIDX] = ind2sub(size(MATbin),find(MATbin));
for i = 1:size(toIDX,1)
    from{i,1} = horzcat('node_',num2str(fromIDX(i)));
    to{i,1} = horzcat('node_',num2str(toIDX(i)));
    value(i,1) = MAT(fromIDX(i),toIDX(i));
end
T = table(from,to,value);
INnet = [out,'_MAT.csv'];
writetable(T,INnet);

Rout = [out,'_Cgram.pdf'];
cmd = ['/Library/Frameworks/R.framework/Versions/3.4/Resources/bin/Rscript --vanilla EdgeBundle.R ',...
    INdeg,' ',INnet,' ',INatt,' ',INatt2,' ',Rout];
system(cmd)
end
