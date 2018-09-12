%% Summary
% explanation

%NOTE: some paths in 'load_stroke_behav' are hard coded, as well as the R
%MCA script. Please edit as appropriate.

% TO DO
% - Other behavioural variables that we might need
% to control for and/or exclude. First language? Chronicity (could be
% regressed)? Previous strokes?
% - normalizing the lesion maps to MNI152 space
% - coding a CLIMS function for the connectome drawing function so that
% colors are even across all comparisons (although if I use other software
% there is no need). In addition, showing histograms of the weights would
% be informative. + figures showing the actual CCA plot (i.e. correlation).
% + a MCAcomponent loading bar graph? + do the 'component space' figure for
% first three components + plot variance accounted for
% - save all figures to results.
% - corbetta white matter idea.
% - correlate communicability loss and the ind CCA weights. (expect
% correlation in Mode 1 but not Mode 2). Result - less clear in the first
% mode (althought I think it looks sensible. Second mode has a clear
% effect. I wonder if the whole thing could be account for by degree, and
% if that is an issue.
% - leave one out prediction with CCA. Do they CCA on all - 1 participants
% then use the weights to predict the behaviour? Correlate the behaviour
% with the predicted behaviour to get fit
% - nice CCA explanation https://stats.stackexchange.com/questions/65692/how-to-visualize-what-canonical-correlation-analysis-does-in-comparison-to-what
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
[~,template] = read([DocsPath,'Atlas/Schaefer100_plus_HOAAL']); %link to template
template = resize_nii(template,[181,217,181]); %when transformed this will change.
%overlap = zeros(size(template));
overlap = zeros(181,217,181); % will be corrected in future
for p = 1:length(P_ID)
    f = [DataPath,'lesionMaps/3_Nii_interp/',P_ID{p},'_interp.nii'];
    [~,tmp] = read(f); % we know these aren't correct.
    lesionSize(p) = sum(sum(sum(tmp)));
    overlap = tmp + overlap;
    
    % count networks
    for i = 1:max(Yeo8Index)
        roi = find(Yeo8Index==i); % find rois within network
        
        idx = zeros(size(template));
        for j = 1:length(roi)
            idx = idx + (template == roi(j));
        end
        
        FuncMap.Lesion(p,i) = sum(tmp(logical(idx)));
    end
    
    % should also calculate overlap with a WM mask - this would be of interest
    % to the corbetta train of thought.
end

% save the overlap nifti for visualization outside of matlab
mat2nii(overlap,[DocsPath,'Results/LesionOverlap.nii'],size(overlap),32,f) 
mat2nii(template,[DocsPath,'Results/template.nii'],size(overlap),32,f) 
% Connectivity lesions

for p = 1:length(P_ID)
    FuncMap.conn(:,:,p) = mapNetworkConn(Cdiff(:,:,p)>0,Yeo8Index);
end

%% MCA
lesionAffection = 5; % I think 5 is sensible? I suppose 8 is 10%.
% number of components = 5;
comps = 5;
tic
MCA = run_MCA(Cdiff,lesionAffection,comps,DocsPath);
toc

%% CCA
% x = behaviours we are interested in (NART,APM,VOSP,CANC,LANG)
% y = the individual MCA loadings from previous step

x = behav.dataTF(:,4:end);
[CCA.A, CCA.B, CCA.R, CCA.U, CCA.V, CCA.stats]=canoncorr(x,MCA.IndWeights);
disp(['p values for each CCA mode: ',num2str(CCA.stats.p)]);

CCA.conload = corr(x,CCA.U);
% further CCA stats.


% correlation with communicability.
% for i = 1:size(Cdiff,3)
%     Communic.pre(i)  = efficiency_wei(Cpre(:,:,i));
%     Communic.post(i) = efficiency_wei(Cpost(:,:,i));
%     Communic.diff(i) = Communic.pre(i)-Communic.post(i);
% end


%
%% Figure 1. Functional network mapping
close all

figure('Color','w','Position',[450 450 600 250]); hold on
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
subplot(1,2,1)

boxplot(FuncMap.Lesion,'PlotStyle','compact','symbol','','Colors','k')

set(gca,'XTick',1:9,'XTickLabel', labels);
title('A.');
xtickangle(45);
ylim([0 4000]);

subplot(1,2,2)
h = imagesc(mean(FuncMap.conn,3));
colorbar
set(gca,'TickLength',[0 0])
set(gca,'YTick',1:9,'YTickLabel', labels);
set(gca,'XTick',1:9,'XTickLabel', labels);
xtickangle(45)
title('B.');
saveas(gcf,[DocsPath,'Results/Figure1a.jpeg']);

% connectome representation of lesion overlap map
figure('Color','w','Position',[450 450 300 450]); hold on
draw_connectome(sum(Cdiff,3),COG,100,120,1);
axis off

saveas(gcf,[DocsPath,'Results/Figure1b.jpeg']);
%% Figure 2: MCA results

figure('Color','w','pos',[100 600 800 400]);

labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
idx = find(MCA.Connindex);

for i = 1:comps
    % connectome plot
    subplot(3,comps,[i,comps+i])
    title(['Component ',num2str(i)]);
    MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    MAT(idx) = MCA.VarWeightsE(:,i);
    draw_connectome(MAT,COG,100,80,0.1,1,100,1);
    xlabel(['MCA Component : ',num2str(i)])
    axis off
    
    %network plot
    subplot(3,comps,i+comps*2)
    MATnet = mapNetworkConn(MAT,Yeo8Index);
    imagesc(MATnet);
    set(gca,'TickLength',[0 0])
    set(gca,'YTick',1:9,'YTickLabel', labels);
    set(gca,'XTick',1:9,'XTickLabel', labels);
    xtickangle(45)
end

% output results for neurmarvl
    % top 100 from each component - give each component a different edge
    % weight. Colour by network.
saveas(gcf,[DocsPath,'Results/Figure2.jpeg']); 
%% Figure 3: CCA
% construct loadings.
figure('Color','w','pos',[100 600 400 200]);
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
Blabels = {'NART','APM','IL','CANC','LANG'};
idx = find(MCA.Connindex);
for i = 1:2
    % construct loadings
    subplot(1,2,i)
    barh(CCA.conload(:,i),'FaceColor',[0.5 0.5 0.5]);
    set(gca,'YTick',1:5,'YTickLabel', Blabels);
    xlabel('Loading');
    xlim([-1 1])
    ylim([0.4 5.5])
    box off
    title(['Mode ',num2str(i),' behaviour loadings']);
end
saveas(gcf,[DocsPath,'Results/Figure3a.jpeg']); 

figure('Color','w','pos',[100 600 400 600]);
for i = 1:2
    % mode in brain space
    subplot(4,2,[i,i+2])
    title(['Mode ',num2str(i),' top connections']);
    Mode = corr(CCA.V(:,i),MCA.Conn)';
    MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    MAT(idx) = Mode;
    
    % draw top 100/bottom 100 only
    draw_connectome(MAT,COG,100,120,0.3,1,100,1);
    axis off
    
    subplot(4,2,i+4)
    draw_connectome(MAT,COG,100,60,0.2,2,100,1);
    axis off
    
    subplot(4,2,i+6)
    MATnet = mapNetworkConn(MAT,Yeo8Index);
    imagesc(MATnet);
    set(gca,'TickLength',[0 0])
    set(gca,'YTick',1:9,'YTickLabel', labels);
    set(gca,'XTick',1:9,'XTickLabel', labels);
    xtickangle(45) 
end
saveas(gcf,[DocsPath,'Results/Figure3b.jpeg']); 

%% SFigure 1: Dimensions of the MCA
figure('Color','w','pos',[100 600 800 400]);
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
idx = find(MCA.Connindex);
comps = size(MCA.VarWeightsE,2);
for i = 1:comps
    % connectome plot
    subplot(3,comps,[i,comps+i])
    title(['Component ',num2str(i)]);
    MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    MAT(idx) = MCA.VarWeightsE(:,i);
    draw_connectome(MAT,COG,100,80,0.1);
    xlabel(['MCA Component : ',num2str(i)])
    axis off
    
    %network plot
    subplot(3,comps,i+comps*2)
    MATnet = mapNetworkConn(MAT,Yeo8Index);
    imagesc(MATnet);
    set(gca,'TickLength',[0 0])
    set(gca,'YTick',1:9,'YTickLabel', labels);
    set(gca,'XTick',1:9,'XTickLabel', labels);
    xtickangle(45)
end
saveas(gcf,[DocsPath,'Results/SFigure1a.jpeg']);

figure('Color','w','pos',[100 600 900 300]);
subplot(1,3,2)
scatter3(MCA.IndWeights(:,1),MCA.IndWeights(:,2),MCA.IndWeights(:,3),...
    50,MCA.IndWeights(:,1),'filled'); hold on
xlabel('MCA Component 1')
ylabel('MCA Component 2')
zlabel('MCA Component 3')

for i = [50,60] % two data points to highlight
scatter3(MCA.IndWeights(i,1),MCA.IndWeights(i,2),MCA.IndWeights(i,3),...
    150,'r'); hold on
end
view(35,25)

subplot(1,3,1)
[I,map] = imread([DocsPath,'Results/MCA/P128_example'],'png');
imshow(I,map);
title('Low MCA dimension 1 value Sub');

subplot(1,3,3)
[I,map] = imread([DocsPath,'Results/MCA/P158_example'],'png');
imshow(I,map);
title('High MCA dimension 1 value Sub');
saveas(gcf,[DocsPath,'Results/SFigure1b.jpeg']); 
%% SFigure2: Fully weighted modes
figure('Color','w','pos',[100 600 400 600]);
for i = 1:2
    % mode in brain space
    subplot(4,2,[i,i+2])
    title(['Mode ',num2str(i),' weighted']);
    Mode = corr(CCA.V(:,i),MCA.Conn)';
    MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    MAT(idx) = Mode;
    
    % draw top 100/bottom 100 only
    draw_connectome(MAT,COG,100,120,0.2);
    axis off
    
    subplot(4,2,i+4)
    draw_connectome(MAT,COG,100,60,0.2,2);
    axis off
    
    subplot(4,2,i+6)
    MATnet = mapNetworkConn(MAT,Yeo8Index);
    imagesc(MATnet);
    set(gca,'TickLength',[0 0])
    set(gca,'YTick',1:9,'YTickLabel', labels);
    set(gca,'XTick',1:9,'XTickLabel', labels);
    xtickangle(45) 
end
saveas(gcf,[DocsPath,'Results/SFigure2.jpeg']); 