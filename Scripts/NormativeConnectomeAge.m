function [ConnectomeAge] = NormativeConnectomeAge(inputArg1,inputArg2)
%UNTITLED3 Summary of this function goes here
%  Detailed explanation goes here

% connectomic age
AI = load([[basedir,'tracts',dataType],P_ID{1},'_Lesion.mat']);
Cdata = load(AI.Analysis.path2connectome,'age','sub');
for i = 1:length(P_ID)
    
    % load analysis information
    AI = load([[basedir,'tracts',dataType],P_ID{i},'_Lesion.mat']);
    
    for j = 1:length(AI.Analysis.subIDX)
        idx = AI.Analysis.subIDX(j)== Cdata.sub;
        tmp(j) = max(Cdata.age(idx));
    end
    
    ConnectomeAge.raw{i} = tmp;
    ConnectomeAge.range(i,1) = min(ConnectomeAge.raw{i});
    ConnectomeAge.range(i,2) = max(ConnectomeAge.raw{i});
    ConnectomeAge.range(i,3) = ConnectomeAge.range(i,2)-ConnectomeAge.range(i,1);
    ConnectomeAge.mean(i) = mean(ConnectomeAge.raw{i});
    ConnectomeAge.diff(i) = abs(ConnectomeAge.mean(i)-behav.data(i,2));
end

disp(['Average range of connectomes = ',num2str(mean(ConnectomeAge.range(:,3))),...
    ', std = ',num2str(std(ConnectomeAge.range(:,3))),...
    ' and distance to actual age = ',num2str(mean(ConnectomeAge.diff))]);
end

