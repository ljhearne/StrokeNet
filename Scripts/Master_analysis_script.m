%% Summary
% explanation

%NOTE: a key function 'load_stroke_behav' is hard coded. Please edit as
%appropriate.

% TO DO/ Things to consider: Other behavioural variables that we might need
% to control for and/or exclude. First language? Chronicity (could be
% regressed)? Previous strokes?

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%add path to BCT

%% inputs
dataType = 'conbound15/'; %data type
parcLabel = '240'; % label for parcellation
behav.variables = [3,4,8,10,11,12,70,31]; % see 'key' variable for further info.

% load data
load([DocsPath,'Atlas/',parcLabel,'COG.mat']); % atlas COG
load([DocsPath,'Atlas/',parcLabel,'parcellation_Yeo8Index.mat']); % atlas network affiliation
[Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,parcLabel,'/']); % connectomes

[data, key, P_ID] = load_stroke_behav; % load behaviour
behav.data = data(:,behav.variables);

%% exclusions
exclude = sum(isnan(behav.data),2)>0; %missing behav data
exclude = exclude+nodata>0; %missing lesion maps
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

% reverse code the Bell's cancellation task.
behav.data(:,7) = behav.data(:,7)*-1;

%transform the data to avoid weighting the CCA unfairly (Smith et al.,
%2016). A log or log2p transform may also be considered.
behav.dataTF = normal_transform(behav.data);

%% Participant demographics
disp([num2str(length(P_ID)),' participants']);
disp([num2str(sum(behav.data(:,1))),' males'])
disp(['Mean age = ',num2str(mean(behav.data(:,2))),...
    ', std = ',num2str(std(behav.data(:,2))),...
    ', range = ',num2str(min(behav.data(:,2))),...
    ' - ',num2str(max(behav.data(:,2)))]);
disp(['Mean education = ',num2str(mean(behav.data(:,3))),...
    ', std = ',num2str(std(behav.data(:,3))),...
    ', range = ',num2str(min(behav.data(:,3))),...
    ' - ',num2str(max(behav.data(:,3)))]);

% connectome density
Node = size(Cpre,1);
NodeTotal = (Node*(Node-1))/2;
for i = 1:length(P_ID)
    density.pre(i) = sum(sum(Cpre(:,:,i)>0))/NodeTotal;
    density.post(i) = sum(sum(Cpost(:,:,i)>0))/NodeTotal;
end

disp(['Average connectome density pre = ',num2str(mean(density.pre)),...
    ' & post = ',num2str(mean(density.post))]);

% normative connectome age (need to be on server with the actual normative
% connectomes to calculate).
%[ConnectomeAge] = NormativeConnectomeAge(inputArg1,inputArg2)

%% Lesion functional network mapping

% Actual lesions
[~,template] = read([DocsPath,'Atlas/Schaefer200_plus_HOAAL']); %link to template
for p = 1:length(P_ID)
   % [hdr,tmp] = read([DataPath,'lesionMaps/3_Nii_interp/',P_ID{i},'_interp.nii']);
    
    
% should also calculate overlap with a WM mask - this would be of interest
% to the corbetta train of thought.
end

% Connectivity lesions
for p = 1:length(P_ID)
    
    tmp = Cdiff(:,:,p) > 0; %binary - could also do weighted
    tmp = tmp+tmp'; %symmetrize
    
    for i = 1:max(Yeo8Index)
        for j = 1:max(Yeo8Index)
            idxR = Yeo8Index==i;
            idxC = Yeo8Index==j;
            FuncMap.conn(i,j,p) = sum(sum(tmp(idxR,idxC)));    
        end
    end
end

%% Figure 1. Functional network mapping
close all

figure('Color','w','Position',[450 450 600 250]); hold on
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
subplot(1,2,1)

title('A.');

subplot(1,2,2)
h = imagesc(mean(FuncMap.conn,3));
colorbar
set(gca,'TickLength',[0 0])
set(gca,'YTick',1:9,'YTickLabel', labels);
set(gca,'XTick',1:9,'XTickLabel', labels);
title('B.');