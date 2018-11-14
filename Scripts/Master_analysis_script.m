%% Summary
% explanation

% TO DO
% - Other behavioural variables that we might need to think about: first
% language and chronicity. At the least I should plot chronicity as a
% histogram

% - consider how to plot results (I'm thinking connectogram via R and
% connectome workbench)

% - nice CCA explanation https://stats.stackexchange.com/questions/65692/
%how-to-visualize-what-canonical-correlation-analysis-does-in-comparison-to-what
%

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%add path to BCT

%% inputs
PARC = 'SCH240';
LNM=1; %this is a bit slow
FIGS = 1;
RENDERS = 0;

dataType = 'conbound20/'; %data type
behav.variables = [3,4,8,10,11,12,70,31]; % see 'key' variable for further info.

if strcmp(PARC,'BN')
    parcLabel = 'BN';
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,parcLabel,'/']); % connectomes
elseif strcmp(PARC,'SCH240')
    parcLabel = '240'; % label for parcellation
    [~,template] = read([DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']); %link to template
    load([DocsPath,'Atlas/Schaefer200/',parcLabel,'COG.mat']); % atlas COG
    load([DocsPath,'Atlas/Schaefer200/',parcLabel,'parcellation_Yeo8Index.mat']); % atlas network affiliation
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,'r',parcLabel,'/']); % connectomes
end

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
for i = 1:Node
    for j = 1:Node
        %age
        Conn = squeeze(Cpre(i,j,:));
        [rMAT(i,j),~] = corr(Conn,behav.data(:,2));
    end
end

%% Lesion functional network mapping
if LNM==1
    
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
            FuncMap.Lesion(p,i) = sum(tmp(logical(idx)));
            FuncMap.Lesionperc(p,i) = sum(tmp(logical(idx)))/lesionSize(p);
        end
    end
    
    
    % save the overlap nifti for visualization outside of matlab
    mat2nii(overlap,[DocsPath,'Results/LesMap/LesionOverlap.nii'],size(overlap),32,f)
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

%% Figures

%------------------------------------------------%
% ONLY THE BRAVE SHOULD VENTURE BEYOND THIS POINT
%------------------------------------------------%

Blabels = {'Age','NART','APM','IL','CANC','LANG'};
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};

if FIGS == 1
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
    t=title('Sub-02 "Pre"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    %"Post" SUB002 matrix
    ax1 = subplot(3,5,11);
    plotdata = Cpost(:,:,2)>0;
    plotdata = plotdata + plotdata'; %sym
    lims = [0, max(max(plotdata))];
    imagesc(plotdata,lims)
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Sub-02 "Post"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    %Difference SUB002 matrix
    ax1 = subplot(3,5,7);
    plotdata = Cdiff(:,:,2)>0;
    plotdata = plotdata + plotdata'; %sym
    lims = [0, max(max(plotdata))];
    imagesc(plotdata,lims)
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Sub-02 "Lesioned"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    % Lesioned connectivity input (subj by connection)
    ax1 = subplot(3,5,3:5);
    plotdata = double(MCA.Conn);
    %data(data==0)=2;
    %data = data -1;
    imagesc(plotdata);
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Group lesioned connectivity');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    %
    % behavioural matrix
    ax2 = subplot(3,5,8);
    plotdata = x;
    lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    imagesc(plotdata,lims);
    ylabel('Subjects');
    xlabel('Variables');
    xticks([])
    yticks([])
    colormap(ax2,bwrmap)
    t=title('Behaviour');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    % colobar for illustrator
    %subplot(3,5,9)
    %lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    %cb = colorbar('Ticks',lims,'TickLabels',{'Impaired','Intact'});
    %cb.Label.String = 'Behaviour';
    
    % component matrix
    ax2 = subplot(3,5,10);
    plotdata = MCA.IndWeights;
    lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    imagesc(plotdata,lims);
    xticks([])
    yticks([])
    colormap(ax2,bwrmap)
    t=title('Components');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
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
    % subplot(3,5,14)
    % stemplot(CCA,1);
    % set(gca,'YTick',1:6,'YTickLabel', {'var 1','var 2','var 3','var 4','var 5','var 6'});
    % %xlabel('Loading');
    % xlim([-1 1])
    % ylim([0.4 size(x,2)+0.5])
    % box off
    % t=title('CCA results');
    % t.FontSize = 10;
    % t.FontWeight = 'bold';
    
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic'],'epsc');
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic.svg']);
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic.png']);
    
    %% Methods NKI atlas
    figure('Color','w','Position',[450 450 700 300]); hold on
    NKI = load('normativeConnectomes/NKIdetails'); %calculated on server
    
    subplot(1,4,1)
    histogram(NKI.NKIage)
    box off
    t = title('NKI age');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    subplot(1,4,2)
    histogram(NKI.NKIsex)
    box off
    t = title('NKI gender');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    set(gca,'XTick',0:1,'XTickLabel', {'Female','Male'});
    
    subplot(1,4,3:4)
    % plot all connectommic ages.
    [~,idx] = sort(behav.data(:,2),'ascend');
    for i = 1:length(P_ID)
        j = idx(i);
        scatter(repmat(i,1,length(NKI.ConnectomeAge.raw{j})),NKI.ConnectomeAge.raw{j},...
            '.','MarkerEdgeAlpha',0.5,'MarkerEdgeColor',[0.5 0.5 0.5]); hold on
        h = scatter(i,behav.data(j,2),'k','filled'); hold on
    end
    xlabel('Population')
    ylabel('Age')
    saveas(gcf,[DocsPath,'Figures/Methods/NKI.svg']);
    close all
    
    %% Figure 1. Functional network mapping
    if LNM==1
        figure('Color','w','Position',[450 450 600 250]); hold on
        subplot(1,2,1)
        %data = log(FuncMap.Lesion);
        data = FuncMap.Lesionperc;
        for i = 1:size(FuncMap.Lesion,2)
            y = (rand(length(data),1) - 0.5)*.15; %jitter
            
            scatter(y+i,data(:,i)*100,...
                'MarkerFaceAlpha',0.5,'MarkerFaceColor',[0.5 0.5 0.5],...
                'MarkerEdgeAlpha',0.5,'MarkerEdgeColor',[0.5 0.5 0.5]); hold on
        end
        
        set(gca,'XTick',1:9,'XTickLabel', labels);
        title('A.');
        xtickangle(45);
        ylabel('% total lesion size');
        
        subplot(1,2,2)
        cols = [0, 0, 144
            255, 255, 255
            144, 0, 0]./255;
        MAT = mean(FuncMap.conn,3);
        setCmap(cols);
        
        imagesc(MAT,[max(max(MAT))*-1,max(max(MAT))])
        set(gca,'TickLength',[0 0])
        set(gca,'YTick',1:9,'YTickLabel', labels);
        set(gca,'XTick',1:9,'XTickLabel', labels);
        xtickangle(45)
        title('B.');
        saveas(gcf,[DocsPath,'Results/LesMap/LesionMapping.svg']);
        saveas(gcf,[DocsPath,'Results/LesMap/LesionMapping.jpeg']);
        
        % connectome representation of lesion overlap map
        MAT = sum(Cdiff>0,3);
        deg = sum(MAT+MAT');
        out = [DocsPath,'Results/LesMap/EdgeRender'];
        %surficeEdgeVis(MAT,COG,deg,ones(length(COG),1),[5,max(max(MAT))],out)
        %SLICES = 72,108,143,180,216,252
    end
    %% Figure 2: MCA results
    
    idx = find(MCA.Connindex);
    
    if RENDERS==1
        for i = 1:comps
            % matrix plot
            
            MAT = zeros(size(Cdiff,1),size(Cdiff,1));
            MAT(idx) = MCA.VarWeightsE(:,i);
            
            %             % save nifti for further figures
            %             weighted_degree = sum(MAT+MAT');
            %             output = zeros(size(template));
            %             for roi = 1:Node
            %                 loc = template==roi;
            %                 output(loc) = weighted_degree(roi);
            %             end
            %             mat2nii(output,[DocsPath,'Results/MCA/Comp',num2str(i),'.nii'],size(output),32,[DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']);
            %
            %             % surface rendering
            %             out = [DocsPath,'Results/MCA/CompMAP',num2str(i)];
            %             NIFTI = [DocsPath,'Results/MCA/Comp',num2str(1),'.nii'];
            %             thresh = ceil(max(abs(weighted_degree)));
            %             surficeMapVis([DocsPath,'Results/MCA/Comp',num2str(i),'.nii'],thresh,out)
            %
            %thresholded
            N = 100;
            
            % abs top N connections
            %     newMAT = zeros(size(MAT));
            %     MATthresh = abs(MAT);
            %     tmp = sort(MATthresh(:),'descend');
            %     MATthresh = MATthresh >= tmp(N);
            %     newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            %     MAT = newMAT;
            
            % top N/2 from each direction?
            newMAT = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'descend');
            MATthresh = MATthresh > tmp(N/2);
            newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            
            newMATneg = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'ascend');
            MATthresh = MATthresh < tmp(N/2);
            newMATneg(find(MATthresh>0)) = MAT(MATthresh>0);
            newMAT = newMAT+newMATneg;
            
            %thresholded edge diagram
            thresh = [0,max(abs(MAT))];
            out = [DocsPath,'Results/MCA/Comp',num2str(i),'thresh',num2str(N)];
            surficeEdgeVis(newMAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
        end
    end
    %% Figure 3: CCA
    
    % behavioural correlation
    figure('Color','w','pos',[100 600 200 200]);
    cols = [0, 0, 144
        255, 255, 255
        144, 0, 0]./255;
    
    setCmap(cols);
    imagesc(corr(x),[max(max(abs(x)))*-1,max(max(abs(x)))])
    
    labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
    %bluecol = [.4,.6,.95];
    idx = find(MCA.Connindex);
    
    %correlation figure
    figure('Color','w','pos',[100 600 400 200]);
    for i = 1:2
        subplot(1,2,i)
        scatter(CCA.V(:,i),CCA.U(:,i),...
            'MarkerEdgeColor',[0.6,0.6,0.6],...
            'MarkerFaceAlpha',0.5,...
            'MarkerEdgeAlpha',0.5,...
            'MarkerFaceColor',[0.6,0.6,0.6]); hold on;
        h=lsline;
        set(h,'Color','k');
    end
    
    %behavioural loadings
    figure('Color','w','pos',[100 600 400 200]);
    for i = 1:2
        subplot(1,2,i)
        
        stemplot(CCA,i);
        set(gca,'YTick',1:6,'YTickLabel', Blabels);
        xlim([-1 1])
        ylim([0.4 size(x,2)+0.5])
        box off
        title(['Mode ',num2str(i),' behaviour loadings']);
    end
    saveas(gcf,[DocsPath,'Results/CCA/BehavLoading.jpeg']);
    %saveas(gcf,[DocsPath,'Results/CCA/BehavLoading.svg']);
    
    %functional networks
    figure('Color','w','pos',[100 600 400 200]);
    
    for i = 1:2
        subplot(1,2,i)
        Mode = corr(CCA.V(:,i),MCA.Conn)';
        MAT = zeros(size(Cdiff,1),size(Cdiff,1));
        MAT(idx) = Mode*-1;
        MATnet = mapNetworkConn(MAT,Yeo8Index);
        
        setCmap(cols);
        imagesc(MATnet,[max(max(abs(MATnet)))*-1,max(max(abs(MATnet)))])
        
        set(gca,'TickLength',[0 0])
        set(gca,'YTick',1:9,'YTickLabel', labels);
        set(gca,'XTick',1:9,'XTickLabel', labels);
        xtickangle(45)
    end
    
    %connectivity loadings
    if RENDERS==1
        for i = 1:2
            % mode in brain space
            Mode = corr(CCA.V(:,i),MCA.Conn)';
            MAT = zeros(size(Cdiff,1),size(Cdiff,1));
            MAT(idx) = Mode*-1;
            
%             % save nifti for further figures
%             weighted_degree = sum(MAT+MAT');
%             output = zeros(size(template));
%             for roi = 1:Node
%                 loc = template==roi;
%                 output(loc) = weighted_degree(roi);
%             end
%             mat2nii(output,[DocsPath,'Results/CCA/Mode',num2str(i),'.nii'],size(output),32,[DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']);
%             
%             % surface rendering
%             out = [DocsPath,'Results/CCA/ModeMAP',num2str(i)];
%             NIFTI = [DocsPath,'Results/CCA/Mode',num2str(1),'.nii'];
%             thresh = ceil(max(abs(weighted_degree)));
%             surficeMapVis([DocsPath,'Results/CCA/Mode',num2str(i),'.nii'],thresh,out)
%             
            %thresholded
            N = 100;
            % abs top N connections
            
            %     newMAT = zeros(size(MAT));
            %     MATthresh = abs(MAT);
            %     tmp = sort(MATthresh(:),'descend');
            %     MATthresh = MATthresh >= tmp(N);
            %     newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            %     MAT = newMAT;
            
            % top N/2 from each direction?
            newMAT = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'descend');
            MATthresh = MATthresh > tmp(N/2);
            newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            
            newMATneg = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'ascend');
            MATthresh = MATthresh < tmp(N/2);
            newMATneg(find(MATthresh>0)) = MAT(MATthresh>0);
            newMAT = newMAT+newMATneg;
            
            %thresholded edge diagram
            thresh = [0,max(abs(Mode))];
            out = [DocsPath,'Results/CCA/Mode',num2str(i),'thresh',num2str(N)];
            surficeEdgeVis(newMAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
            
            %thresholded bundle diagram
            ConnectogramR(newMAT,COG,Yeo8Index,labels,out)
        end
    end
    
    %% SFigure 1: Dimensions of the MCA
    %
    %     figure('Color','w','pos',[100 600 900 300]);
    %     subplot(1,3,2)
    %     scatter(MCA.IndWeights(:,1),MCA.IndWeights(:,2),...
    %         50,MCA.IndWeights(:,1),'filled'); hold on
    %     xlabel('MCA Component 1')
    %     ylabel('MCA Component 2')
    %
    %     for i = [50,60] % two data points to highlight
    %         scatter(MCA.IndWeights(i,1),MCA.IndWeights(i,2),...
    %             150,'r'); hold on
    %     end
    %
    %     subplot(1,3,1)
    %     [I,map] = imread([DocsPath,'Results/MCA/P128_example'],'png');
    %     imshow(I,map);
    %     title('Low MCA dimension 1 value Sub');
    %
    %     subplot(1,3,3)
    %     [I,map] = imread([DocsPath,'Results/MCA/P158_example'],'png');
    %     imshow(I,map);
    %     title('High MCA dimension 1 value Sub');
    %     saveas(gcf,[DocsPath,'Results/MCA/Dimensionexample.jpeg']);
    %
    %     % %% SFigure2: Fully weighted modes
    %     % close all
    %     % figure('Color','w','pos',[100 600 400 600]);
    %     % for i = 1:2
    %     %     % mode in brain space
    %     %     subplot(4,2,[i,i+2])
    %     %     title(['Mode ',num2str(i),' weighted']);
    %     %     Mode = corr(CCA.V(:,i),MCA.Conn)';
    %     %     MAT = zeros(size(Cdiff,1),size(Cdiff,1));
    %     %     MAT(idx) = Mode;
    %     %
    %     %     % draw top 100/bottom 100 only
    %     %     draw_connectome(MAT,COG,100,120,0.2);
    %     %     axis off
    %     %
    %     %     subplot(4,2,i+4)
    %     %     draw_connectome(MAT,COG,100,60,0.2,2);
    %     %     axis off
    %     %%% Summary
% explanation

% TO DO
% - Other behavioural variables that we might need to think about: first
% language and chronicity. At the least I should plot chronicity as a
% histogram

% - consider how to plot results (I'm thinking connectogram via R and
% connectome workbench)

% - nice CCA explanation https://stats.stackexchange.com/questions/65692/
%how-to-visualize-what-canonical-correlation-analysis-does-in-comparison-to-what
%
% - add IF statements for parcellations

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%add path to BCT

%% inputs
PARC = 'SCH240';

dataType = 'conbound20/'; %data type
behav.variables = [3,4,8,10,11,12,70,31]; % see 'key' variable for further info.

if strcmp(PARC,'BN')
    parcLabel = 'BN';
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,parcLabel,'/']); % connectomes
elseif strcmp(PARC,'SCH240')
    parcLabel = '240'; % label for parcellation
    [~,template] = read([DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']); %link to template
    load([DocsPath,'Atlas/Schaefer200/',parcLabel,'COG.mat']); % atlas COG
    load([DocsPath,'Atlas/Schaefer200/',parcLabel,'parcellation_Yeo8Index.mat']); % atlas network affiliation
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',dataType,'r',parcLabel,'/']); % connectomes
end

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
            FuncMap.Lesion(p,i) = sum(tmp(logical(idx)));
            FuncMap.Lesionperc(p,i) = sum(tmp(logical(idx)))/lesionSize(p);
        end
    end
    
    
    % save the overlap nifti for visualization outside of matlab
    mat2nii(overlap,[DocsPath,'Results/LesMap/LesionOverlap.nii'],size(overlap),32,f)
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

%% Figures

Blabels = {'Age','NART','APM','IL','CANC','LANG'};
labels = {'Vis';'SM';'DAN';'Sal';'Lim';'FPN';'DMN';'SubC';'Cer'};
FIGS = 1;
RENDERS = 1;

if FIGS == 1
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
    t=title('Sub-02 "Pre"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    %"Post" SUB002 matrix
    ax1 = subplot(3,5,11);
    plotdata = Cpost(:,:,2)>0;
    plotdata = plotdata + plotdata'; %sym
    lims = [0, max(max(plotdata))];
    imagesc(plotdata,lims)
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Sub-02 "Post"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    %Difference SUB002 matrix
    ax1 = subplot(3,5,7);
    plotdata = Cdiff(:,:,2)>0;
    plotdata = plotdata + plotdata'; %sym
    lims = [0, max(max(plotdata))];
    imagesc(plotdata,lims)
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Sub-02 "Lesioned"');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    % Lesioned connectivity input (subj by connection)
    ax1 = subplot(3,5,3:5);
    plotdata = double(MCA.Conn);
    %data(data==0)=2;
    %data = data -1;
    imagesc(plotdata);
    xticks([])
    yticks([])
    colormap(ax1,bwmap)
    t=title('Group lesioned connectivity');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    %
    % behavioural matrix
    ax2 = subplot(3,5,8);
    plotdata = x;
    lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    imagesc(plotdata,lims);
    ylabel('Subjects');
    xlabel('Variables');
    xticks([])
    yticks([])
    colormap(ax2,bwrmap)
    t=title('Behaviour');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    % colobar for illustrator
    %subplot(3,5,9)
    %lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    %cb = colorbar('Ticks',lims,'TickLabels',{'Impaired','Intact'});
    %cb.Label.String = 'Behaviour';
    
    % component matrix
    ax2 = subplot(3,5,10);
    plotdata = MCA.IndWeights;
    lims = [max(max(abs(plotdata)))*-1,max(max(abs(plotdata)))];
    imagesc(plotdata,lims);
    xticks([])
    yticks([])
    colormap(ax2,bwrmap)
    t=title('Components');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
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
    % subplot(3,5,14)
    % stemplot(CCA,1);
    % set(gca,'YTick',1:6,'YTickLabel', {'var 1','var 2','var 3','var 4','var 5','var 6'});
    % %xlabel('Loading');
    % xlim([-1 1])
    % ylim([0.4 size(x,2)+0.5])
    % box off
    % t=title('CCA results');
    % t.FontSize = 10;
    % t.FontWeight = 'bold';
    
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic'],'epsc');
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic.svg']);
    saveas(gcf,[DocsPath,'Figures/Methods/MethodsSchematic.png']);
    
    %% Methods NKI atlas
    figure('Color','w','Position',[450 450 700 300]); hold on
    NKI = load('normativeConnectomes/NKIdetails'); %calculated on server
    
    subplot(1,4,1)
    histogram(NKI.NKIage)
    box off
    t = title('NKI age');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    
    subplot(1,4,2)
    histogram(NKI.NKIsex)
    box off
    t = title('NKI gender');
    t.FontSize = 10;
    t.FontWeight = 'normal';
    set(gca,'XTick',0:1,'XTickLabel', {'Female','Male'});
    
    subplot(1,4,3:4)
    % plot all connectommic ages.
    [~,idx] = sort(behav.data(:,2),'ascend');
    for i = 1:length(P_ID)
        j = idx(i);
        scatter(repmat(i,1,length(NKI.ConnectomeAge.raw{j})),NKI.ConnectomeAge.raw{j},...
            '.','MarkerEdgeAlpha',0.5,'MarkerEdgeColor',[0.5 0.5 0.5]); hold on
        h = scatter(i,behav.data(j,2),'k','filled'); hold on
    end
    xlabel('Population')
    ylabel('Age')
    saveas(gcf,[DocsPath,'Figures/Methods/NKI.svg']);
    close all
    
    %% Figure 1. Functional network mapping
    if LNM==1
        figure('Color','w','Position',[450 450 600 250]); hold on
        subplot(1,2,1)
        %data = log(FuncMap.Lesion);
        data = FuncMap.Lesionperc;
        for i = 1:size(FuncMap.Lesion,2)
            y = (rand(length(data),1) - 0.5)*.15; %jitter
            
            scatter(y+i,data(:,i)*100,...
                'MarkerFaceAlpha',0.5,'MarkerFaceColor',[0.5 0.5 0.5],...
                'MarkerEdgeAlpha',0.5,'MarkerEdgeColor',[0.5 0.5 0.5]); hold on
        end
        
        set(gca,'XTick',1:9,'XTickLabel', labels);
        title('A.');
        xtickangle(45);
        ylabel('% total lesion size');
        
        subplot(1,2,2)
        cols = [0, 0, 144
            255, 255, 255
            144, 0, 0]./255;
        MAT = mean(FuncMap.conn,3);
        setCmap(cols);
        
        imagesc(MAT,[max(max(MAT))*-1,max(max(MAT))])
        set(gca,'TickLength',[0 0])
        set(gca,'YTick',1:9,'YTickLabel', labels);
        set(gca,'XTick',1:9,'XTickLabel', labels);
        xtickangle(45)
        title('B.');
        saveas(gcf,[DocsPath,'Results/LesMap/LesionMapping.svg']);
        saveas(gcf,[DocsPath,'Results/LesMap/LesionMapping.jpeg']);
        
        % connectome representation of lesion overlap map
        MAT = sum(Cdiff>0,3);
        deg = sum(MAT+MAT');
        out = [DocsPath,'Results/LesMap/EdgeRender'];
        %surficeEdgeVis(MAT,COG,deg,ones(length(COG),1),[5,max(max(MAT))],out)
        %SLICES = 72,108,143,180,216,252
    end
    %% Figure 2: MCA results
    
    idx = find(MCA.Connindex);
    
    if RENDERS==1
        for i = 1:comps
            % matrix plot
            
            MAT = zeros(size(Cdiff,1),size(Cdiff,1));
            MAT(idx) = MCA.VarWeightsE(:,i);
            
            %             % save nifti for further figures
            %             weighted_degree = sum(MAT+MAT');
            %             output = zeros(size(template));
            %             for roi = 1:Node
            %                 loc = template==roi;
            %                 output(loc) = weighted_degree(roi);
            %             end
            %             mat2nii(output,[DocsPath,'Results/MCA/Comp',num2str(i),'.nii'],size(output),32,[DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']);
            %
            %             % surface rendering
            %             out = [DocsPath,'Results/MCA/CompMAP',num2str(i)];
            %             NIFTI = [DocsPath,'Results/MCA/Comp',num2str(1),'.nii'];
            %             thresh = ceil(max(abs(weighted_degree)));
            %             surficeMapVis([DocsPath,'Results/MCA/Comp',num2str(i),'.nii'],thresh,out)
            %
            %thresholded
            N = 100;
            
            % abs top N connections
            %     newMAT = zeros(size(MAT));
            %     MATthresh = abs(MAT);
            %     tmp = sort(MATthresh(:),'descend');
            %     MATthresh = MATthresh >= tmp(N);
            %     newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            %     MAT = newMAT;
            
            % top N/2 from each direction?
            newMAT = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'descend');
            MATthresh = MATthresh > tmp(N/2);
            newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            
            newMATneg = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'ascend');
            MATthresh = MATthresh < tmp(N/2);
            newMATneg(find(MATthresh>0)) = MAT(MATthresh>0);
            newMAT = newMAT+newMATneg;
            
            %thresholded edge diagram
            thresh = [0,max(abs(MAT))];
            out = [DocsPath,'Results/MCA/Comp',num2str(i),'thresh',num2str(N)];
            surficeEdgeVis(newMAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
        end
    end
    %% Figure 3: CCA
    
    % behavioural correlation
    figure('Color','w','pos',[100 600 250 200]);
    cols = [0, 0, 144
        255, 255, 255
        144, 0, 0]./255;
    
    setCmap(cols);
    data = corr(x);
    data(logical(eye(length(data)))) = 0;  
    imagesc(data,[max(max(abs(data)))*-1,max(max(abs(data)))])
    colorbar
    set(gca,'TickLength',[0 0])
    set(gca,'YTick',1:6,'YTickLabel', Blabels);
    set(gca,'XTick',1:6,'XTickLabel', Blabels);
    xtickangle(45)
    saveas(gcf,[DocsPath,'Results/CCA/BehavCorrelation.jpeg']);
    
    %correlation figure
    figure('Color','w','pos',[100 600 400 200]);
    for i = 1:2
        subplot(1,2,i)
        scatter(CCA.V(:,i),CCA.U(:,i),...
            'MarkerEdgeColor',[0.6,0.6,0.6],...
            'MarkerFaceAlpha',0.5,...
            'MarkerEdgeAlpha',0.5,...
            'MarkerFaceColor',[0.6,0.6,0.6]); hold on;
        h=lsline;
        set(h,'Color','k');
    end
    saveas(gcf,[DocsPath,'Results/CCA/ModeCorrelation.jpeg']);
    
    %behavioural loadings
    figure('Color','w','pos',[100 600 400 200]);
    for i = 1:2
        subplot(1,2,i)
        
        stemplot(CCA,i);
        set(gca,'YTick',1:6,'YTickLabel', Blabels);
        xlim([-1 1])
        ylim([0.4 size(x,2)+0.5])
        box off
        title(['Mode ',num2str(i),' behaviour loadings']);
    end
    saveas(gcf,[DocsPath,'Results/CCA/BehavLoading.jpeg']);
    %saveas(gcf,[DocsPath,'Results/CCA/BehavLoading.svg']);
    
    %functional networks
    figure('Color','w','pos',[100 600 400 200]);
    
    for i = 1:2
        subplot(1,2,i)
        Mode = corr(CCA.V(:,i),MCA.Conn)';
        MAT = zeros(size(Cdiff,1),size(Cdiff,1));
        MAT(idx) = Mode*-1;
        MATnet = mapNetworkConn(MAT,Yeo8Index);
        
        setCmap(cols);
        imagesc(MATnet,[max(max(abs(MATnet)))*-1,max(max(abs(MATnet)))])
        
        set(gca,'TickLength',[0 0])
        set(gca,'YTick',1:9,'YTickLabel', labels);
        set(gca,'XTick',1:9,'XTickLabel', labels);
        xtickangle(45)
    end
    saveas(gcf,[DocsPath,'Results/CCA/CCAFuncNets.jpeg']);
    
    %connectivity loadings
    if RENDERS==1
        for i = 1:2
            % mode in brain space
            Mode = corr(CCA.V(:,i),MCA.Conn)';
            MAT = zeros(size(Cdiff,1),size(Cdiff,1));
            MAT(idx) = Mode*-1;
            
            % save nifti for further figures
            weighted_degree = sum(MAT+MAT');
            output = zeros(size(template));
            for roi = 1:Node
                loc = template==roi;
                output(loc) = weighted_degree(roi);
            end
            mat2nii(output,[DocsPath,'Results/CCA/Mode',num2str(i),'.nii'],size(output),32,[DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']);
            
            % surface rendering
            out = [DocsPath,'Results/CCA/ModeMAP',num2str(i)];
            NIFTI = [DocsPath,'Results/CCA/Mode',num2str(1),'.nii'];
            thresh = ceil(max(abs(weighted_degree)));
            surficeMapVis([DocsPath,'Results/CCA/Mode',num2str(i),'.nii'],thresh,out)
            
            %thresholded
            N = 100;
            % abs top N connections
            
            %     newMAT = zeros(size(MAT));
            %     MATthresh = abs(MAT);
            %     tmp = sort(MATthresh(:),'descend');
            %     MATthresh = MATthresh >= tmp(N);
            %     newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            %     MAT = newMAT;
            
            % top N/2 from each direction?
            newMAT = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'descend');
            MATthresh = MATthresh > tmp(N/2);
            newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
            
            newMATneg = zeros(size(MAT));
            MATthresh = MAT;
            tmp = sort(MATthresh(:),'ascend');
            MATthresh = MATthresh < tmp(N/2);
            newMATneg(find(MATthresh>0)) = MAT(MATthresh>0);
            newMAT = newMAT+newMATneg;
            
            %thresholded edge diagram
            thresh = [0,max(abs(Mode))];
            out = [DocsPath,'Results/CCA/Mode',num2str(i),'thresh',num2str(N)];
            surficeEdgeVis(newMAT,COG,Yeo8Index,ones(length(COG),1),thresh,out)
            
            %thresholded bundle diagram
            ConnectogramR(newMAT,COG,Yeo8Index,labels,out)
        end
    end
    
    %% SFigure 1: Dimensions of the MCA
    %
    %     figure('Color','w','pos',[100 600 900 300]);
    %     subplot(1,3,2)
    %     scatter(MCA.IndWeights(:,1),MCA.IndWeights(:,2),...
    %         50,MCA.IndWeights(:,1),'filled'); hold on
    %     xlabel('MCA Component 1')
    %     ylabel('MCA Component 2')
    %
    %     for i = [50,60] % two data points to highlight
    %         scatter(MCA.IndWeights(i,1),MCA.IndWeights(i,2),...
    %             150,'r'); hold on
    %     end
    %
    %     subplot(1,3,1)
    %     [I,map] = imread([DocsPath,'Results/MCA/P128_example'],'png');
    %     imshow(I,map);
    %     title('Low MCA dimension 1 value Sub');
    %
    %     subplot(1,3,3)
    %     [I,map] = imread([DocsPath,'Results/MCA/P158_example'],'png');
    %     imshow(I,map);
    %     title('High MCA dimension 1 value Sub');
    %     saveas(gcf,[DocsPath,'Results/MCA/Dimensionexample.jpeg']);
    %
    %     
    %     % end
    %     % saveas(gcf,[DocsPath,'Results/SFigure2.jpeg']);
end
end