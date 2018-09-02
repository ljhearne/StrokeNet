%Hub analysis

clearvars
close all

addpath('functions');
addpath(genpath('/projects/sw49/BCT/'));
addpath(genpath('/projects/sw49/Pls/'));
%addpath(genpath('/home/lukehearne/R/'));

% inputs
basedir = '/scratch/sw49/1_LEADStrokeMapping/';
dataType = '_conbound15/'; %data type
parcLabel = '140/'; % label for parcellation
load('/projects/sw49/Atlas/140COG.mat');  

behav.variables = [3,4,8,10,11,12,70,31]; %may be altered in future
lesionThresh = 0; % 5% lesion affection

% load connectomes
[Cpre,Cpost,nodata] = load_connectomes([basedir,'connectomes',dataType,parcLabel]);
Nodes = size(Cpre,1);

% load behaviour
[data, key, P_ID] = load_stroke_behav;
behav.data = data(:,behav.variables);

% exclusions
exclude = sum(isnan(behav.data),2)>0; %missing behav data
exclude = exclude+nodata>0; %missing lesion data
behav.data(exclude,:) = [];
P_ID(exclude) = [];
Cpre(:,:,exclude) = []; 
Cpost(:,:,exclude) = [];
Cdiff = Cpre-Cpost;

exclude = squeeze(sum(sum(Cdiff,1),2)==0); %missing connectivity data
behav.data(exclude,:) = [];
P_ID(exclude) = [];
Cpre(:,:,exclude) = []; 
Cpost(:,:,exclude) = [];
Cdiff(:,:,exclude) = [];
% transform the spatial neglect variable
behav.data(:,7) = behav.data(:,7)*-1;
%behav.data(:,6) = normal_transform(behav.data(:,6));
%behav.data(:,7) = normal_transform(behav.data(:,7))*-1;
behav.data = normal_transform(behav.data);
% sample size
SampSize = size(Cpre,3);

%% CCA Connectivity
idx = sum(Cdiff>0,3)>5; %index informative voxels
%idx(1:100,1:100) = 0;
for i = 1:SampSize
    tmp = Cdiff(:,:,i)>0; %binarize
    Conn(i,:) = tmp(idx);
end
%
%focus on subcortical

% ---
% 
% Setting up the data,
data = Conn;
behavinput = behav.data(:,4:end);
% where data is your dependent variable(s), and behavinput are your independent variables.
% 
datamat_lst={data};
option.stacked_behavdata=behavinput;
% 
option.method=3; %will need to set to 3 if doing rotated-PLS.
option.num_perm=1000;
option.num_boot=2000;
% 
% 
% where, behavinput equals the behavioural data of interest, and data is your brain data
% 
% ---
% 
% To run,%
nsubjs = SampSize;
result = pls_analysis(datamat_lst, nsubjs, 1, option);
% 
% where, nsubjs requires number of subjects to be entered
% 
% ---
% 
% Interpreting the results,
% 
% 
% Determining significance (i.e, significant mode[s])
%% 
% look for values in result.perm_result.sprob that are < 0.05
result.perm_result.sprob
% 
% Correlation of behavioural measures within the mode 
%  
figure
for i = 1:2
subplot(1,2,i)
barh(result.lvcorrs(:,i));
set(gca,'YTick',1:5,'YTickLabel', {'NART','APM','GS','COC','LANG'});
xlabel('poor <---  Loading  ---> good');
ylabel('Variable');
end
% 
% 
% "Significant" weight of original brain variables (i.e. the tracks) on the mode
% 
%%


%%
figure
nidx = find(idx);
for i = 1:2
    subplot(1,2,i)
    x = abs(result.boot_result.compare_u(:,i))<2.7;
    xw = result.boot_result.compare_u(:,i);
    xw(x) = 0;
    
    MAT = zeros(Nodes,Nodes);
    MAT(nidx) = xw;
    draw_connectome(MAT,COG,20,150); hold on
    %legend({'damaged','intact'});
   
end
