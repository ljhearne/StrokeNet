%Hub analysis

% You need to think about symmetric matrices for the hub analysis -
% probably need to divide some metrics by two (which may change statistics
% but not patterns) [the rest of my scripts just use upper triangle so
% that's why I'm confused here].

clearvars
close all

addpath('functions');
addpath(genpath('/projects/sw49/BCT/'));
addpath(genpath('/projects/sw49/FSLNets/'));
addpath(genpath('/home/lukehearne/R/'));

% inputs
basedir = '/scratch/sw49/1_LEADStrokeMapping/';
dataType = '_conbound20/'; %data type
parcLabel = '214/'; % label for parcellation
load('/projects/sw49/Atlas/114COG.mat');
%load('/projects/sw49/Atlas/140parcellation_Yeo8Index.mat');

behav.variables = [3,4,8,10,11,12,70,31];

% load connectomes
[~,~,nodata, Cpre,Cpost] = load_connectomes([basedir,'connectomes',dataType,parcLabel]);
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

%% Simulate lesion analysis
perms = 10;
k = 0.15; %top 15%

for i = 1:SampSize
    
    %calculating post-lesion processing metric
    Cmcy.post(i) = sum(sum(getCommunicability(Cpost(:,:,i),1,1)));
    %Cmcy.post(i) = efficiency_wei(Cpost(:,:,i));
    
    % calculate connection class loss
    tmp = sort(sum(Cpre(:,:,i)),'descend');
    Klevel = tmp(round(length(tmp)*k));
    [~,~,~,HubMat] = find_hubs(Cpre(:,:,i),Klevel);

    tmp = Cdiff(:,:,i);
    for h = 1:3
        idxhub = logical(HubMat(:,:,h));
        ConClass.bin(i,h) = sum(sum(tmp(idxhub)>0));
        ConClass.wei(i,h) = sum(sum(tmp(idxhub)));
    end
    
    % generate simulations
    c = Cdiff(:,:,i);
    deg = sum(sum(c>0));
    
    idx = find(Cpre(:,:,i)>0); %index of possible connections to lesion
    for p = 1:perms
        l = idx(randperm(length(idx)));
        l = l(1:deg);
        
        %calculate processing metric
        Csim = Cpre(:,:,i);
        Csim(l) = 0;
        Cmcy.postsim(i,p) = sum(sum(getCommunicability(Csim,1,1)));
        %Cmcy.postsim(i,p) = efficiency_wei(Csim);
        
        % calculate loss of hubs
        tmp = (Cpre(:,:,i) - Csim);
        for h = 1:3
            idxhub = logical(HubMat(:,:,h));
            ConClass.binsim(i,p,h) = sum(sum(tmp(idxhub)>0));
            ConClass.weisim(i,p,h) = sum(sum(tmp(idxhub)));
        end
    end
    i
end

%% between groups t-test
[~,p,~] = ttest2(Cmcy.post,Cmcy.postsim(:))
for h = 1:3
[~,p,~] = ttest2(ConClass.wei(:,h),reshape(ConClass.weisim(:,:,h),[SampSize*perms,1]))
end
%plot
figure('Color',[1 1 1],'pos',[1000 600 450 350]);
figparam.lw = 1;
figparam.alpha = 0.5;
figparam.col = [0.7 0.7 0.7];%[0.53 0.8 0.92];
figparam.s = 15;
%--------------------------
box_and_scatterplot(Cmcy.post,1,figparam.lw,figparam.s,...
    figparam.col,figparam.alpha); hold on
box_and_scatterplot(Cmcy.postsim(:),2,figparam.lw,figparam.s,...
    figparam.col,figparam.alpha); hold on

% Stroke is less damaging to global communication than would be expected by
% a similiar degree random lesion.

figure('Color',[1 1 1],'pos',[1000 600 600 400]);

for h = 1:3
    subplot(2,3,h)
    box_and_scatterplot(ConClass.wei(:,h),1,figparam.lw,figparam.s,...
        figparam.col,figparam.alpha); hold on
    box_and_scatterplot(reshape(ConClass.weisim(:,:,h),[SampSize*perms,1]),2,figparam.lw,figparam.s,...
        figparam.col,figparam.alpha); hold on
    xlim([0.5 2.5])
end

for h = 1:3
    subplot(2,3,h+3)
    box_and_scatterplot(ConClass.bin(:,h),1,figparam.lw,figparam.s,...
        figparam.col,figparam.alpha); hold on
    box_and_scatterplot(reshape(ConClass.binsim(:,:,h),[SampSize*perms,1]),2,figparam.lw,figparam.s,...
        figparam.col,figparam.alpha); hold on
    xlim([0.5 2.5])
end

% not specific to a connection class - simulated lesions seem to damage
% more highly weighted connections across the board BUT less hubs (in
% number). A ... confusing? result that seems to indicate stroke damage is
% associated with damage to hubs/feeders that are 'relatively' weak (!?).

% I suppose this makes me think that perhaps it is not fair to lump all
% strokes into a single group - is this analysis really that informative?
%% -------- Graph analysis

% k = 0.15; %top 15%
% 
% for i = 1:SampSize
%     % calculate k at individual level
%     tmp = sort(sum(Cpre(:,:,i)),'descend');
%     Klevel = tmp(round(length(tmp)*k));
%     [ConCount(i,:),~,ConStren(i,:),HubMat] = find_hubs(Cpre(:,:,i),Klevel);
%     HubPrint(:,:,i) = HubMat(:,:,1);
%     
%     % count the number of connections in each connection class.
%     tmp = Cdiff(:,:,i)>0;
%     
%     for h = 1:3
%         idx = logical(HubMat(:,:,h));
%         HubDamage(i,h) = sum(tmp(idx))/2;
%         HubDamageCont(i,h) = (sum(tmp(idx))/2)/sum(sum(idx)); %divided by number of total conn in class
%     end
% end
% 
% % communicability
% for i = 1:SampSize
%     for l = 1 % no difference across this parameter
%         Cmcy.pre(i,l) = sum(sum(getCommunicability(Cpre(:,:,i),l,1)))/2;
%         Cmcy.post(i,l) = sum(sum(getCommunicability(Cpost(:,:,i),l,1)))/2;
%         Cmcy.diff(i,l) = Cmcy.pre(i,l) - Cmcy.post(i,l);
%     end
% end
% 
% % calculate lesion size
% for i = 1:SampSize
%     lesionfile = [basedir,'Lesions/',P_ID{i},'_interp.nii'];
%     [~,data] = read(lesionfile);
%     lesionSize(i,1) = sum(sum(sum(data)));
% end
% 
% % linear regression - does hub connection damage predict communicability
% % when controlling for lesion size & other types of damage?
% X = [sqrt(lesionSize),HubDamage];
% lm = fitlm(X,Cmcy.diff,'linear');
% disp(lm)
% 
% %%%
% %OK, so the degree within each connection type are so highly correlated
% %that the multiple regression is probably not appopriate (predictors are
% %too highly correlated).
% %% Plots
% close all
% 
% figure('Color',[1 1 1],'pos',[1000 600 550 350]);
% figparam.lw = 1;
% figparam.alpha = 0.5;
% figparam.col = [0.7 0.7 0.7];%[0.53 0.8 0.92];
% figparam.s = 15;
% 
% %--------------------------
% subplot(1,3,1)
% box_and_scatterplot(Cmcy.pre,1,figparam.lw,figparam.s,...
%     figparam.col,figparam.alpha); hold on
% box_and_scatterplot(Cmcy.post,2,figparam.lw,figparam.s,...
%     figparam.col,figparam.alpha); hold on
% 
% set(gca,'FontName', 'Helvetica','FontSize', 10,'Box','off',...
% 'TickDir','out','ygrid','off','XLim',[.5 2.5]);
% 
% ylabel('Communicability')
% set(gca, 'XTick',[1,2],'XTickLabel',{'Pre','Post'});
% 
% %--------------------------
% subplot(1,3,[2,3])
% figparam.col = [1,.8,0];
% scatter(HubDamage(:,3),Cmcy.diff,...
%         'MarkerEdgeColor',figparam.col,...
%         'LineWidth',figparam.lw,...
%         'MarkerFaceAlpha',figparam.alpha,...
%         'MarkerEdgeAlpha',figparam.alpha,...
%         'MarkerFaceColor', figparam.col,...
%         'SizeData',figparam.s); hold on 
% 
% figparam.col = [1,0.5,0];
% scatter(HubDamage(:,2),Cmcy.diff,...
%         'MarkerEdgeColor',figparam.col,...
%         'LineWidth',figparam.lw,...
%         'MarkerFaceAlpha',figparam.alpha,...
%         'MarkerEdgeAlpha',figparam.alpha,...
%         'MarkerFaceColor', figparam.col,...
%         'SizeData',figparam.s); hold on
%     
% figparam.col = [1,0,0];
% scatter(HubDamage(:,1),Cmcy.diff,...
%         'MarkerEdgeColor',figparam.col,...
%         'LineWidth',figparam.lw,...
%         'MarkerFaceAlpha',figparam.alpha,...
%         'MarkerEdgeAlpha',figparam.alpha,...
%         'MarkerFaceColor', figparam.col,...
%         'SizeData',figparam.s); hold on
% 
% h = lsline;
% set(h(3),'color',[1,.8,0],'LineWidth',1)
% set(h(2),'color',[1,.5,0],'LineWidth',1)
% set(h(1),'color',[1,0,0],'LineWidth',1)
% 
% set(gca,'FontName', 'Helvetica','FontSize', 10,'Box','off',...
% 'TickDir','out','ygrid','off','XLim',[0 max(max(HubDamage))]);
%     
% ylabel('Change in Communicability')
% xlabel('Hub connection damage');
% 
% %%
% % I think the high colinearity between the variables precludes any
% % meaningingful assessment of each connection classes contribution to i)
% % global processing loss and ii) behaviour. I guess we can conclude that
% % strokes don't really attack structural hubs.
% figure('Color',[1 1 1],'pos',[1000 600 750 250]);
% subplot(1,3,1)
% scatter(HubDamage(:,1),HubDamage(:,2),'k'); hold on
% lsline
% ylabel('Feeder damage')
% xlabel('Hub damage');
% 
% subplot(1,3,2)
% scatter(HubDamage(:,1),HubDamage(:,3),'k'); hold on
% lsline
% ylabel('Periphery damage')
% xlabel('Hub damage');
% 
% subplot(1,3,3)
% scatter(HubDamage(:,2),HubDamage(:,3),'k'); hold on
% lsline
% ylabel('Periphery damage')
% xlabel('Feeder damage');
% 
% %% Print edge and node files
% figure('Color',[1 1 1],'pos',[1000 600 350 350]);
% draw_connectome(sum(HubPrint,3),COG,20,500)
% xlabel('Hubs');