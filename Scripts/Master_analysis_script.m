%% Summary
% explanation

% TO DO
% - Other behavioural variables that we might need to think about: first
% language and chronicity. At the least I should plot chronicity as a
% histogram
%
% - consider how to plot results (I'm thinking connectogram via R and
% connectome workbench)
%
% - nice CCA explanation https://stats.stackexchange.com/questions/65692/
%how-to-visualize-what-canonical-correlation-analysis-does-in-comparison-to-what
%
% - permutation / bootstrap with replacement test (need to talk to AP)

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%add path to BCT

%% inputs
dataType = 'conbound20/'; %data type
parcLabel = '240'; % label for parcellation
[~,template] = read([DocsPath,'Atlas/rSchaefer200_plus_HO.nii']); %link to template
behav.variables = [3,4,8,10,11,12,70,31]; % see 'key' variable for further info.

% load data
load([DocsPath,'Atlas/',parcLabel,'COG.mat']); % atlas COG
load([DocsPath,'Atlas/',parcLabel,'parcellation_Yeo8Index.mat']); % atlas network affiliation
[Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,'r',parcLabel,'/']); % connectomes

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
disp([num2str(sum(behav.data(:,1))),' females'])
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
%% Normative connectome sanity checks

% correlation between age and connectivity weights
idx = ones(size(Cpre(:,:,1)));
idx = triu(idx,1);

for i = 1:Node
    for j = 1:Node
        %age
        Conn = squeeze(Cpre(i,j,:));
        [rMAT(i,j),~] = corr(Conn,behav.data(:,2));
    end
end

%% Lesion functional network mapping
LNM=0; %this is a bit slow
if LNM==1
    
    % need to think whether this is accurate enough.
%     [~,wmMask] = read([DocsPath,'Atlas/white.nii']);
%     [~,gmMask] = read([DocsPath,'Atlas/grey.nii']);
%     % resize masks
%     [wmMask] = resize_nii(wmMask,size(template));
%     [gmMask] = resize_nii(gmMask,size(template));
%     %arbrary thresh were most voxels are accounted for
%     thresh = 125; 
%     wmMask = wmMask > thresh;
%     gmMask = gmMask > thresh;
    
    % Actual lesions
    overlap = zeros(size(template));
    lesionSize = zeros(length(P_ID),1);
    
    for p = 1:length(P_ID)
        f = [DataPath,'lesionMaps/3_rNii/r',P_ID{p},'.nii'];
        [~,tmp] = read(f);
        lesionSize(p) = sum(sum(sum(tmp)));
        overlap = double(tmp) + overlap;
        
        % count networks
        for i = 1:max(Yeo8Index)
            roi = find(Yeo8Index==i); % find rois within network
            
            idx = zeros(size(template)); %index of network
            for j = 1:length(roi)
                idx = idx + (template == roi(j));
            end
            
            % expressed as percentage of lesion size
            FuncMap.Lesion(p,i) = sum(tmp(logical(idx)))/lesionSize(p);
        end
    end

    
    % save the overlap nifti for visualization outside of matlab
    mat2nii(overlap,[DocsPath,'Results/LesionOverlap.nii'],size(overlap),32,f)
    mat2nii(template,[DocsPath,'Results/template.nii'],size(overlap),32,f)
    % Connectivity lesions
    
    for p = 1:length(P_ID)
        FuncMap.conn(:,:,p) = mapNetworkConn(Cdiff(:,:,p)>0,Yeo8Index);
    end
end
%% MCA

% first define the behavioural variables to be included as this will match
% to the components
x = behav.dataTF(:,[2,4:end]);

lesionAffection = 4; % I think > 4 is sensible? I suppose >7 is 10%.
comps = size(x,2); % number of components

% clean any old MCA files
system('rm /Users/luke/Documents/Projects/StrokeNet/Docs/Results/MCA/MCA*')
[MCA] = run_MCA(Cdiff,lesionAffection,comps,DocsPath);

% % % % regress lesion size from the components
% for i = 1:comps
%     [~,~,MCA.IndWeights(:,i)] = regress(MCA.IndWeights(:,i),...
%         [ones(length(MCA.IndWeights),1),lesionSize']);
% end

%% CCA
% x = behaviours we are interested in (NART,APM,VOSP,CANC,LANG)
% y = the individual MCA loadings from previous step

[CCA.A, CCA.B, CCA.R, CCA.U, CCA.V, CCA.stats]=canoncorr(x,MCA.IndWeights);
disp(['p values for each CCA mode: ',num2str(CCA.stats.p)]);

CCA.conload = corr(x,CCA.U); % is it CCA.U or CCA.V?

% permutation testing
PERMTEST=1;
if PERMTEST==1
    Perms=10000; %I would increase for final results
    
    CCA.Rnull=zeros(Perms,1);
    for i=1:Perms
        ind_rand=randperm(length(P_ID))';
        [~,~,tmp,~,~,~]=canoncorr(x,MCA.IndWeights(ind_rand,:));
        CCA.Rnull(i) = max(tmp);
    end
end

%Corrected p-values based on permutations (I don't think these are needed
%in this analysis because there is no complex family structure as in Smith
%et al., 2015).
CCA.pcorr=zeros(size(CCA.R));
for i=1:length(CCA.R)
    CCA.pcorr(i)=sum(CCA.Rnull>=CCA.R(i))/Perms; 
end
disp(['Permutation corrected p values for each CCA mode: ',num2str(CCA.pcorr)]);

%Confidence interval weights bootstrap
Perms=5000;
As=zeros(size(x,2),Perms);
Bs=zeros(size(MCA.IndWeights,2),Perms); 
for i=1:Perms
    ind_rand=ceil(rand(size(x,1),1)*size(x,1)); 
    [AA,BB,~,UU,VV]=canoncorr(x(ind_rand,:),MCA.IndWeights(ind_rand,:));
    
    if corr(AA(:,1),CCA.A(:,1))<0
        AA(:,1)=AA(:,1)*-1; BB(:,1)=BB(:,1)*-1;
    end
    As(:,i)=AA(:,1); 
    Bs(:,i)=BB(:,1);
    CCA.conloadNull(:,:,i) = corr(x,UU);
end

%Determine when confidence intervals are exceeded for each weight
Lwr=floor(0.20*Perms); 
Upr=ceil((1-0.20)*Perms); 
xA=size(x,2);
for i=1:size(x,2)
    tmp=sort(As(i,:)); 
    if tmp(Upr)*tmp(Lwr) > 0
        xA(i)=1; 
    else
        xA(i)=0;
    end
end
%% Draft figures
Blabels = {'Age','NART','APM','IL','CANC','LANG'};

%% Methods figure
close all
figure('Color','w','Position',[450 450 700 400]); hold on

%generate two colourmaps
c = [255, 255, 255
     127.5, 127.5, 127.5
     0, 0, 0]./255;
bwmap = interp1([0 255/2 255]/255,c,linspace(0,1,255));

c = [0, 0, 144
     255, 255, 255
     144, 0, 0]./255;
bwrmap = interp1([0 255/2 255]/255,c,linspace(0,1,255));

% "Pre" SUB002 matrix
ax1 = subplot(3,5,1);
plotdata = Cpre(:,:,2)>0;
plotdata = plotdata + plotdata'; %sym
lims = [0, max(max(plotdata))];
imagesc(plotdata,lims)
xticks([])
yticks([])
colormap(ax1,bwmap)

%"Post" SUB002 matrix
ax1 = subplot(3,5,11);
plotdata = Cpost(:,:,2)>0;
plotdata = plotdata + plotdata'; %sym
lims = [0, max(max(plotdata))];
imagesc(plotdata,lims)
xticks([])
yticks([])
colormap(ax1,bwmap)

%Difference SUB002 matrix
ax1 = subplot(3,5,7);
plotdata = Cdiff(:,:,2)>0;
plotdata = plotdata + plotdata'; %sym
lims = [0, max(max(plotdata))];
imagesc(plotdata,lims)
xticks([])
yticks([])
colormap(ax1,bwmap)

% Lesioned connectivity input (subj by connection)
ax1 = subplot(3,5,3:5);
plotdata = double(MCA.Conn);
%data(data==0)=2;
%data = data -1;
imagesc(plotdata);
xticks([])
yticks([])
colormap(ax1,bwmap)
% 
% behavioural matrix
ax2 = subplot(3,5,8);
plotdata = x;
lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
imagesc(plotdata,lims);
ylabel = 'Subjects';
xlabel = 'Variables';
xticks([])
yticks([])
colormap(ax2,bwrmap)

% colobar for illustrator
subplot(3,5,9)
lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
cb = colorbar('Ticks',lims,'TickLabels',{'Impaired','Intact'});
cb.Label.String = 'Behaviour';

% component matrix
subplot(3,5,10)
plotdata = MCA.IndWeights;
lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
imagesc(plotdata);
xticks([])
yticks([])
 
% CCA correlation
subplot(3,5,13)
scatter(CCA.V(:,1),CCA.U(:,1),...
        'MarkerEdgeColor',[0.6,0.6,0.6],...
        'MarkerFaceAlpha',0.5,...
        'MarkerEdgeAlpha',0.5,...
        'MarkerFaceColor',[0.6,0.6,0.6]); hold on;
h=lsline;
set(h,'Color','k')

% behavioural loadings
subplot(3,5,14)
stemplot(CCA,1);
set(gca,'YTick',1:6,'YTickLabel', {'var 1','var 2','var 3','var 4','var 5','var 6'});
%xlabel('Loading');
xlim([-1 1])
ylim([0.4 size(x,2)+0.5])
box off

%% Normative Connectome Sanity Check
% figure('Color','w','pos',[100 600 400 400]);
% title('Age related change');
% subplot(3,2,[1,3])
% draw_connectome(rMAT,COG,100,80,0.1,1,100,1);
% axis off
% subplot(3,2,5)
% draw_connectome(rMAT,COG,100,60,0.2,2,100,1);
% axis off
out = [DocsPath,'Results/SanityCheck/AgeCorr'];
%MAT = rMAT;
%MAT(abs(MAT)<0.5)=0;

%% Figure 1. Functional network mapping
if LNM==1
    figure('Color','w','Position',[450 450 600 250]); hold on
    labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
    subplot(1,2,1)
    
    %boxplot(FuncMap.Lesion*100,'PlotStyle','compact','symbol','','Colors','k')
    for i = 1:size(FuncMap.Lesion,2)
        scatter(repmat(i,length(FuncMap.Lesion),1),FuncMap.Lesion(:,i)*100); hold on
    end
    
    set(gca,'XTick',1:9,'XTickLabel', labels);
    title('A.');
    xtickangle(45);
    ylim([0 100]);
    
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
end
% %% Figure 2: MCA results
% 
% figure('Color','w','pos',[100 600 800 400]);
% 
% labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
% idx = find(MCA.Connindex);
% 
% for i = 1:comps
%     % connectome plot
%     subplot(3,comps,[i,comps+i])
%     title(['Component ',num2str(i)]);
%     MAT = zeros(size(Cdiff,1),size(Cdiff,1));
%     MAT(idx) = MCA.VarWeightsE(:,i);
%     draw_connectome(MAT,COG,100,80,0.1,1,100,1);
%     %xlabel(['MCA Component : ',num2str(i)]);
%     axis off
%     
%     %network plot
%     subplot(3,comps,i+comps*2)
%     MATnet = mapNetworkConn(MAT,Yeo8Index);
%     imagesc(MATnet);
%     set(gca,'TickLength',[0 0])
%     set(gca,'YTick',1:9,'YTickLabel', labels);
%     set(gca,'XTick',1:9,'XTickLabel', labels);
%     xtickangle(45)
% end
% 
% % output results for neurmarvl
% % top 100 from each component - give each component a different edge
% % weight. Colour by network.
% saveas(gcf,[DocsPath,'Results/Figure2.jpeg']);
%% Figure 3: CCA
% construct loadings.
figure('Color','w','pos',[100 600 400 200]);
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
%bluecol = [.4,.6,.95];
idx = find(MCA.Connindex);
for i = 1:2
    subplot(1,2,i)
    
    stemplot(CCA,i);
   
    set(gca,'YTick',1:6,'YTickLabel', Blabels);
    xlim([-1 1])
    ylim([0.4 size(x,2)+0.5])
    box off
    title(['Mode ',num2str(i),' behaviour loadings']);
end
saveas(gcf,[DocsPath,'Results/Figure3a.jpeg']);

for i = 1:2
    % mode in brain space
    subplot(4,4,[i,i+4])
    title(['Mode ',num2str(i),' top connections']);
    Mode = corr(CCA.V(:,i),MCA.Conn)';
    MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    MAT(idx) = Mode;
   
    %full weighted
    thresh = [0,max(max(max(abs(MAT))))];
    out = [DocsPath,'Results/CCA/MODE',num2str(i),'full'];
    surficeVisbundleVis(MAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
    
    %thresholded
    % abs top N connections
    N = 200;
    newMAT = zeros(size(MAT));
    MATthresh = abs(MAT);
    tmp = sort(MATthresh(:),'descend');
    MATthresh = MATthresh >= tmp(N);
    newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
    
    MAT = newMAT;
    thresh = [0,max(max(max(abs(MAT))))];
    out = [DocsPath,'Results/CCA/MODE',num2str(i),'thresh'];
    surficeVisbundleVis(MAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
    %     % save nifti for further figures
    %     weighted_degree = sum(MAT+MAT');
    %     output = zeros(size(template));
    %     for roi = 1:Node
    %         loc = template==roi;
    %         output(loc) = weighted_degree(roi);
    %     end
    %     mat2nii(output,[DocsPath,'Results/Mode',num2str(i),'.nii'],size(output),32,f);
end


% %% SFigure 1: Dimensions of the MCA
% figure('Color','w','pos',[100 600 800 400]);
% labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
% idx = find(MCA.Connindex);
% comps = size(MCA.VarWeightsE,2);
% for i = 1:comps
%     % connectome plot
%     subplot(3,comps,[i,comps+i])
%     title(['Component ',num2str(i)]);
%     MAT = zeros(size(Cdiff,1),size(Cdiff,1));
%     MAT(idx) = MCA.VarWeightsE(:,i);
%     draw_connectome(MAT,COG,100,80,0.1);
%     %    xlabel(['MCA Component : ',num2str(i)])
%     axis off
%     
%     %network plot
%     subplot(3,comps,i+comps*2)
%     MATnet = mapNetworkConn(MAT,Yeo8Index);
%     imagesc(MATnet);
%     set(gca,'TickLength',[0 0])
%     set(gca,'YTick',1:9,'YTickLabel', labels);
%     set(gca,'XTick',1:9,'XTickLabel', labels);
%     xtickangle(45)
% end
% saveas(gcf,[DocsPath,'Results/SFigure1a.jpeg']);
% 
% figure('Color','w','pos',[100 600 900 300]);
% subplot(1,3,2)
% scatter3(MCA.IndWeights(:,1),MCA.IndWeights(:,2),MCA.IndWeights(:,3),...
%     50,MCA.IndWeights(:,1),'filled'); hold on
% %xlabel('MCA Component 1')
% %ylabel('MCA Component 2')
% %zlabel('MCA Component 3')
% 
% for i = [50,60] % two data points to highlight
%     scatter3(MCA.IndWeights(i,1),MCA.IndWeights(i,2),MCA.IndWeights(i,3),...
%         150,'r'); hold on
% end
% view(35,25)
% 
% subplot(1,3,1)
% [I,map] = imread([DocsPath,'Results/MCA/P128_example'],'png');
% imshow(I,map);
% title('Low MCA dimension 1 value Sub');
% 
% subplot(1,3,3)
% [I,map] = imread([DocsPath,'Results/MCA/P158_example'],'png');
% imshow(I,map);
% title('High MCA dimension 1 value Sub');
% saveas(gcf,[DocsPath,'Results/SFigure1b.jpeg']);
% %% SFigure2: Fully weighted modes
% close all
% figure('Color','w','pos',[100 600 400 600]);
% for i = 1:2
%     % mode in brain space
%     subplot(4,2,[i,i+2])
%     title(['Mode ',num2str(i),' weighted']);
%     Mode = corr(CCA.V(:,i),MCA.Conn)';
%     MAT = zeros(size(Cdiff,1),size(Cdiff,1));
%     MAT(idx) = Mode;
%     
%     % draw top 100/bottom 100 only
%     draw_connectome(MAT,COG,100,120,0.2);
%     axis off
%     
%     subplot(4,2,i+4)
%     draw_connectome(MAT,COG,100,60,0.2,2);
%     axis off
%     
%     subplot(4,2,i+6)
%     MATnet = mapNetworkConn(MAT,Yeo8Index);
%     imagesc(MATnet);
%     set(gca,'TickLength',[0 0])
%     set(gca,'YTick',1:9,'YTickLabel', labels);
%     set(gca,'XTick',1:9,'XTickLabel', labels);
%     xtickangle(45)
% end
% saveas(gcf,[DocsPath,'Results/SFigure2.jpeg']);
% 
% figure
% subplot(1,3,1)
% scatter(CCA.V(:,1),CCA.U(:,1));
% subplot(1,3,2)
% scatter(CCA.V(:,2),CCA.U(:,2));
% subplot(1,3,3)
% scatter(CCA.V(:,1),CCA.V(:,2));