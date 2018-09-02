%% Summary
% this script serves as a rudimentary 'methods' section. Note the iputs
% immediately below for the type of connectivity data and parcellation
% used.
% In short, the connectivity data is derived by taking age and gender
% matched structural data from the NKI rockland dataset via LEAD DBS. For
% each participant a 'normative' connectome is derived (PRE) and a lesioned
% normative connectome is estimated by taking into account their lesion map
% (POST). Basically any streamline that passes through the lesion location
% is deleted. A key parameter to test across is the number of connectomes
% to included in each normative connectome. 

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%addpath(genpath('/projects/sw49/BCT'));

% inputs
dataType = '_conbound10/'; %data type
parcLabel = '240'; % label for parcellation
behav.variables = [3,4,8,10,11,12,70,31]; %may be altered in future

% load data
load([DocsPath,Atlas,parcLabel,'COG.mat']); %Atlas COG
load([DocsPath,Atlas,parcLabel,'parcellation_Yeo8Index.mat']); %Atlas network affiliation

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
    disconnected(i) = sum(sum(Cpre(:,:,i),1)+sum(Cpre(:,:,i),2)'==0);
end

disp(['Average density pre = ',num2str(mean(density.pre)),' & post = ',...
    num2str(mean(density.post))]);
disp([num2str(sum(disconnected)), ' empty nodes']);

% connectomic age
AI = load([[basedir,'tracts',dataType],P_ID{1},'_Lesion.mat']);
Cdata = load(AI.Analysis.path2connectome,'age','sub');
for i = 1:length(P_ID)
    
    % load analysis information
    AI = load([[basedir,'tracts',dataType],P_ID{i},'_Lesion.mat']);
    
    for j = 1:length(AI.Analysis.subIDX);
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

figure
lw = 1;
alpha = 0.25;
col = [0.5 0.5 0.5];
s = 30;
a = 0; 
b = 0.2;
%--------------------------
[y,idx] = sort(behav.data(:,2),'ascend');

for i =1:length(y)
    % draw scatter
    data = ConnectomeAge.raw{idx(i)};
    r = a + (b-a).*rand(length(data),1);
    scatter(r+i,data,...
        'MarkerEdgeColor',col,...
        'LineWidth',lw,...
        'MarkerFaceAlpha',alpha,...
        'MarkerEdgeAlpha',alpha,...
        'MarkerFaceColor', col,...
        'SizeData',s); hold on
end

scatter(1:length(y),y,...
        'MarkerEdgeColor','k',...
        'LineWidth',lw,...
        'MarkerFaceColor', 'k',...
        'SizeData',s); hold on
ylabel('Age')
xlabel('Subject (black = real data, grey = norm connecomte');
%% Behaviour
% The behaviour in the analysis includes:
% The NART: often taken as a measure of premorbid IQ, but also seen as a
% measure of crystallized intelligence.
% The APM: Raven's matrices common fluid intelligence test.
% The VOSP: Letter completion task - a basic perception test
% The Bell's Cancellation Task: a common spatial neglect attention test
% Naming language task: a simple language test

figure 
title('Correlation between Vars');
vars = {'NART','APM','GREY','CANC','LANG'};
t = corr(behav.data(:,4:end));
t(logical(eye(size(t))))=0;
imagesc(t);
colorbar
set(gca,'XTick',1:5,'XTickLabel', vars);
set(gca,'YTick',1:5,'YTickLabel', vars);
set(gca,'FontName', 'Helvetica','FontSize', 12,'Box','off','TickDir','out','ygrid','off');

figure('pos',[1000 600 750 250]);
title('Distribution of variables');
for i = 1:5
    subplot(1,5,i)
    box_and_scatterplot(behav.data(:,i+3),1,1,15,...
        [.5 .5 .5],.5); hold on
    ylabel(vars{i});
end

%%
% you can see that the VOSP and BC task are highly skewed. This is not
% unexpected as most people will not show spatial neglect, for example. I
% propose for the CCA we normalize these variables so as to
% not unfairly weight outliers. Below I demonstrate the transformation
% Smith et al., used in their HCP CCA paper but am happy to do something
% else. We can replicate the analyses in non-transformed data.

x = normal_transform(behav.data);

figure('pos',[1000 600 750 250]);
title('transformed variables');

for i = 1:5
    subplot(1,5,i)
    box_and_scatterplot(x(:,i+3),1,1,15,...
        [.5 .5 .5],.5); hold on
    ylabel(vars{i});
end

figure 
title('Correlation between transformed Vars');
vars = {'NART','APM','GREY','CANC','LANG'};
t = corr(x(:,4:end));
t(logical(eye(size(t))))=0;
imagesc(t);
colorbar
set(gca,'XTick',1:5,'XTickLabel', vars);
set(gca,'YTick',1:5,'YTickLabel', vars);
set(gca,'FontName', 'Helvetica','FontSize', 12,'Box','off','TickDir','out','ygrid','off');

%% Lesion brain plot
figure('pos',[1000 600 750 250]);
subplot(1,3,1)
imagesc(sum(Cpre,3));
subplot(1,3,2)
imagesc(sum(Cpost,3));
subplot(1,3,3)
imagesc(sum(Cpre-Cpost,3));

figure('pos',[1000 600 250 250]);
MAT = Cpre-Cpost;
MAT = sum(MAT>0,3);

draw_connectome(MAT,COG,20,500);
set(gca,'FontName', 'Helvetica','FontSize', 10,'Box','off',...
'TickDir','out','ygrid','off','XLim',[-100 100],'YLim',[-110,90]);
title('Top 500 lesioned connections')
set(gca,'xtick',[],'xcolor',[1,1,1],'ytick',[],'ycolor',[1,1,1]);