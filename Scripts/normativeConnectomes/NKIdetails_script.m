%% Summary
% this script gives some basic stats about the NKI sample and how they were
% used in the stroke database

clearvars -except Cdata
close all

addpath('/projects/sw49/Project_scripts/functions');
% inputs
basedir = '/scratch/sw49/';
dataType = '/conbound15/'; %data type
parcLabel = 'r240/'; % label for parcellation
%load('/projects/sw49/Atlas/214COG.mat');
behav.variables = [3,4,8,10,11,12,70,31]; %may be altered in future

% load connectomes
[Cpre,Cpost,nodata] = load_connectomes([basedir,'connectomes',dataType,parcLabel]);

% load behaviour and do exclusions
[data, key, P_ID] = load_stroke_behav;
behav.data = data(:,behav.variables);

exclude = sum(isnan(behav.data),2)>0;
exclude = exclude+nodata>0; %incorporate missing lesion data
behav.data(exclude,:) = [];
P_ID(exclude) = [];
Cpre(:,:,exclude) = []; 
Cpost(:,:,exclude) = [];
behav.data(:,7) = behav.data(:,7)*-1; % reverse coded

%% Atlas details
Analysis.connectomedir = ['/projects/sw49/LEAD/connectomes/dMRI/',...
    'Gibbsconnectome_169 (Horn 2016)/',...
    'data.mat']; %absolute path to the LEAD DBS connectome data
% read in lead connectome
if exist('Cdata') == 0
    disp('loading LeadDBS connectome in workspace...');
    Cdata = load(Analysis.connectomedir);
else
    disp('LeadDBS connectome already in workspace');
end
disp('LeadDBS connectome is in workspace');

[sublabel,subidx] = unique(Cdata.sub);
NKIage = Cdata.age(subidx);
NKIsex = Cdata.sex(subidx);

%% Connectomic age
for i = 1:length(P_ID)
    
    disp(num2str(i));
    
    % load analysis information
    AI = load([[basedir,'tracts',dataType],P_ID{i},'_details.mat']);
    
    [~,~, AI.Analysis.subIDX] = ...
        gen_NormConnectome(Cdata, AI.Analysis.age,AI.Analysis.sex,AI.Analysis.conbound);
    
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

save NKIdetails.mat ConnectomeAge NKIage NKIsex