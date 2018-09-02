%Hub analysis

clearvars
close all

addpath('functions');
addpath(genpath('/projects/sw49/BCT/'));
addpath(genpath('/projects/sw49/NBS1.2/'));

% inputs
basedir = '/scratch/sw49/1_LEADStrokeMapping/';
dataType = '_conbound20/'; %data type
parcLabel = '512/'; % label for parcellation

behav.variables = [3,4,8,10,11,12,70,31]; %may be altered in future

% load connectomes
[~,~,nodata,Cpre,Cpost] = load_connectomes([basedir,'connectomes',dataType,parcLabel]);
%Nodes = size(Cpre,1);

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

% sample size
SampSize = size(Cpre,3);

% communicability
for i = 1:SampSize
    for l = 1 % no difference across this parameter
        Cmcy.pre(i,l) = sum(sum(getCommunicability(Cpre(:,:,i),l,1)));
        Cmcy.post(i,l) = sum(sum(getCommunicability(Cpost(:,:,i),l,1)));
        Cmcy.diff(i,l) = Cmcy.pre(i,l) - Cmcy.post(i,l);
    end
end

% global efficiency
poolobj = MASSIVEpp(1,'/scratch/sw49/scratch');
parfor i = 1:SampSize
        GEpre(i) = efficiency_wei(Cpre(:,:,i));
        GEpost(i) = efficiency_wei(Cpost(:,:,i));
        GEdiff(i) = GEpre(i) - GEpost(i);
        i
end
poolobj = MASSIVEpp(1,'/scratch/sw49/scratch',poolobj);

% calculate lesion size
for i = 1:SampSize
    lesionfile = [basedir,'Lesions/',P_ID{i},'_interp.nii'];
    [~,data] = read(lesionfile);
    lesionSize(i,1) = sum(sum(sum(data)));
end

%% NBS with communicability, controlling for lesion size, age and gender

Design = ones(SampSize,1);
Design(:,2) = GEdiff;
%Design(:,3) = sqrt(lesionSize);
%Design(:,4:5) = behav.data(:,1:2);
save('/projects/sw49/Results/NBS/Design.mat','Design');

save('/projects/sw49/Results/NBS/Matrices.mat','Cdiff');

UI.method.ui='Run NBS'; 
UI.test.ui='t-test';
UI.size.ui='Extent';
UI.thresh.ui='5.5';
UI.perms.ui='100';
UI.alpha.ui='0.05';
UI.contrast.ui='[0,1]'; 
UI.design.ui='/projects/sw49/Results/NBS/Design.mat';
UI.exchange.ui=''; 
UI.matrices.ui='/projects/sw49/Results/NBS/Matrices.mat';
UI.node_coor.ui='/scratch/sw49/1_LEADStrokeMapping/Atlas/512COG.mat';                         
UI.node_label.ui='';

NBSrun(UI);

% %% ----- create "global" variable through norming
% 
% %NART
% newNART = behav.data(:,4)<(100-(1.96*15)); %70.6 is bottom 5th percentile
% 
% for i = 1:SampSize
%     
% % VOSP
% newVOSP(i) = VOSPnorm(behav.data(i,6),behav.data(i,2));
% 
% %APM
% 
% % CoC
% 
% % LANG
% end