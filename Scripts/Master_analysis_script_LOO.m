%% Summary
% Stroke analysis master script

% TO DO
% - Other behavioural variables that we might need to think about: first
% language and chronicity. At the least I should plot chronicity as a
% histogram
% - Clean up voxel versus connectivity related code (figures in particular)
% - Results should be saved in a parcellation by parcellation fashion
% - Implement /(think about? / maybe confer with someone regarding) leave
% one out prediction analysis.

clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';
addpath('functions');

%% Inputs
parc = 'Sch240';
participant_demographics = 1;   % Do you want to complete demographics analysis?

gen_lesiondensity_plot = 0;     % Do you want to do a lesion density plot?

run_lesion_reg = 0;             % Do you want to regress lesion size?

run_MCA        = 0;             % Do you want to perform the LOO MCA? This is slow.

CCA_perms = 1000;               % Number of permutations for significance testing

edgeThreshold  = 0;             % When is an edge considered 'lesioned' within
% participant

lesionAffection = 1;            % How many edges across participants need to be lesioned
% for that edge to be included in the MCA?
% For LOO, it should be at least 1.

num_comps = 5;                 % number of MCA components included in CCA

num_modes = 2;                  % number of modes to investigate

norm_prior = 1;                 % normalize behavioural variables BEFORE leave one out analysis.
% This causes no difference in the results
% (in fact, slightly increases correlation)
% but the predicted values produced are
% outliers (in the sense they are quite
% extreme) which inflates the correlation.
% This is likely due to spatial neglect
% variables having a skewed distribution
% where a simple variable transform using
% SD is not going to perform well.

conbound = 'conbound20/'; %normative connectome data type
behav.CCA = [10,11,19,31,71]; %variables to include in CCA
behav.DEMO = [4,3,8,7]; % demographic variables (age,gender,education,chronicity)
Blabels = {'NART','APM','Q1_spon','Q6_fluency','CANC'};

%% Organise data

if strcmp(parc,'BN')
    nRoi = 246;
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',conbound,parc,'/']); % connectomes
    resultsdir = [DocsPath,'Results/',conbound,parc,'/'];
    load([DocsPath,'Atlas/BNAtlas/BN_Yeo8Index.mat']); % atlas network affiliation
    load([DocsPath,'Atlas/BNAtlas/COG.mat']); % atlas COG
    
elseif strcmp(parc,'Sch214')
    nRoi = 214; % label for parcellation
    [~,template] = read([DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HO.nii']); %link to template
    load([DocsPath,'Atlas/Schaefer200/',num2str(nRoi),'COG.mat']); % atlas COG
    load([DocsPath,'Atlas/Schaefer200/',num2str(nRoi),'parcellation_Yeo8Index.mat']); % atlas network affiliation
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',conbound,parc,'/']); % connectomes
    resultsdir = [DocsPath,'Results/',conbound,parc,'/'];
elseif strcmp(parc,'Sch240')
     nRoi = 240; % label for parcellation
    [~,template] = read([DocsPath,'Atlas/Schaefer200/rSchaefer200_plus_HOAAL.nii']); %link to template
    load([DocsPath,'Atlas/Schaefer200/',num2str(nRoi),'COG.mat']); % atlas COG
    load([DocsPath,'Atlas/Schaefer200/',num2str(nRoi),'parcellation_Yeo8Index.mat']); % atlas network affiliation
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/',conbound,parc,'/']); % connectomes
    resultsdir = [DocsPath,'Results/',conbound,parc,'/'];
elseif strcmp(parc,'voxelwise')
    %we use Schaefer 240 as a reference to enable compatibility with the
    %current code
    [Cpre,Cpost,nodata] = load_connectomes([DataPath,'connectomes/conbound30/Sch214/']); % connectomes
    resultsdir = [DocsPath,'Results/',parc,'/'];
    
end

[data, key, P_ID] = load_stroke_behav; % load behaviour
behav.data = data(:,behav.CCA);
disp('Including the following variables in the CCA:');
for i = 1:length(behav.CCA)
    disp([key{behav.CCA(i)}]);
end
behav.dataDemo = data(:,behav.DEMO);

% results directory
mkdir(resultsdir);
delete([resultsdir,'results.txt']);
diary([resultsdir,'results.txt']);

% Exclusions
% exclude participants with missing behavioural or imaging data.
exclude = sum(isnan(behav.data),2)>0; %missing behav data
disp([num2str(sum(exclude)),' subjects dropped due to missing behaviour']);
exclude = exclude+nodata>0; %missing lesion maps
behav.data(exclude,:) = [];
behav.dataDemo(exclude,:) = [];
P_ID(exclude) = [];
Cpre(:,:,exclude) = [];
Cpost(:,:,exclude) = [];
Cdiff = Cpre-Cpost;

exclude = squeeze(sum(sum(Cdiff,1),2)==0); %missing connectivity data
disp([num2str(sum(exclude)),' subjects dropped due to no tracts']);
behav.data(exclude,:) = [];
behav.dataDemo(exclude,:) = [];
P_ID(exclude) = [];
Cpre(:,:,exclude) = [];
Cpost(:,:,exclude) = [];
Cdiff(:,:,exclude) = [];

%transform the data to avoid weighting the CCA unfairly (Smith et al.,
%2016). A log or log2p transform may also be considered.
behav.dataTF = normal_transform(behav.data);

%check the behavioural data
for i = 1:size(behav.dataTF,2)
    h = kstest(behav.dataTF(:,i));
    if h==1
        disp('Check behavioural data a variable is not normal');
        return
    end
end

% *final* sample size
N = size(behav.data,1);

% *final* behavioural measures
num_meas = size(behav.data,2);

% Load voxelwise data if needed
if strcmp(parc,'voxelwise') || run_lesion_reg==1
    
    disp('... loading voxelwise data');
    for p = 1:N
        f = [DataPath,'lesionMaps/3_rNii/r',P_ID{p},'.nii'];
        [~,tmp] = read(f);
        lesionMaps(:,:,:,p) = double(tmp);
    end
    disp('... finished loading voxelwise data');
end

%% Participant demographics
% prints some basic statistics about the patient and normative connectome
% data
if participant_demographics==1
    
    disp('--------------------------------------');
    disp('PARTICIPANT AND NORM-CONNECTOME INFORMATION');
    print_analysis_info(P_ID,behav.dataDemo,parc,Cpre,Cpost,conbound)
    
end

%% Lesion density plot
if gen_lesiondensity_plot == 1
    disp('... loading voxelwise data for lesion density plot');
    for p = 1:N
        f = [DataPath,'lesionMaps/2_Nii/',P_ID{p},'.nii'];
        [~,tmp] = read(f);
        temp(:,:,:,p) = double(tmp);
    end
    disp('... finished loading voxelwise data');
    lesion_distribution = sum(temp,4);
    
    % save the overlap nifti for visualization outside of matlab
    mat2nii(lesion_distribution,[resultsdir,'LesionOverlap.nii'],size(lesion_distribution),32,f)
    
end
%% Dimensionality reduction: multiple correspondance analysis (MCA)
disp('--------------------------------------');
disp('MULTIPLE CORRESPONDANCE ANALYSIS');
disp(['First ',num2str(num_comps),' components considered']);
% define brain-based features (connectivity or voxels) to be included
if strcmp(parc,'voxelwise')
    tmp = size(lesionMaps,1)*size(lesionMaps,2)*size(lesionMaps,3);
    for p = 1:N
        Cvec(p,:) = reshape(lesionMaps(:,:,:,p),[1,tmp]);
    end
    
else
    idx = triu(ones(nRoi),1);
    for p = 1:N
        tmp = Cdiff(:,:,p)>edgeThreshold; %binarized
        Cvec(p,:) = tmp(logical(idx));
    end
end

% run the MCA - returns a structure with inputs
MCA = run_MCA_LOO(Cvec,lesionAffection,resultsdir,run_MCA);

if strcmp(parc,'voxelwise')==0
    % transform the MCA index of useful connections back into edge
    % so that we can use it to display results later
    tmp = triu(ones(nRoi),1);
    tmp(tmp==1) = MCA.index;
    MCA.index = tmp;
end

if run_lesion_reg==1
    disp('... Doing lesion regression')
    
    % regress lesion size from the MCA components.
    for i = 1:size(MCA.IndWeights,2)
        x = [ones(length(lesionSize),1),lesionSize];
        [~,~,residual] = regress(MCA.IndWeights(:,i),x);
        MCA.IndWeights(:,i) = residual;
    end
end

%% Leave one out loop and CCA
disp('--------------------------------------');
disp('CANONICAL CORRELATION ANALYSIS');

CCA = run_CCA_LOO(behav.dataTF,MCA,num_comps,num_modes,norm_prior);
disp(['CCA: mean r for mode 1 and 2:',num2str(mean(CCA.r))])

% Compare predictions and ascribe significance via permutation
% r values are compared to shuffled r values from the first mode *only*

for i = 1:CCA_perms
    r = 1:N;
    r = r(randperm(length(r)));
    tmp = run_CCA_LOO(behav.dataTF(r,:),MCA,num_comps,num_modes,norm_prior);
    CCA.perm_r(i) = mean(tmp.r(:,1));
    CCA.perm_predicted_r(i,:) = tmp.predicted_r(:,1); %only take first mode
    
    if i==90
        disp([ 9 num2str(i),' perms are finished...'])
    elseif i==900
        disp([ 9 num2str(i),' perms are finished...'])
    elseif i ==4900
        disp([ 9 num2str(i),' perms are finished...'])
    elseif i ==9900
        disp([ 9 num2str(i),' perms are finished...'])
    end
end

p = invprctile(CCA.perm_r,mean(CCA.r(:,1)));
disp(['CCA: permutation-based p value for Mode 1: ',num2str(p)])

p = invprctile(CCA.perm_r,mean(CCA.r(:,2)));
disp(['CCA: permutation-based p value for Mode 2: ',num2str(p)])

% Each behaviour
for i = 1:num_meas
    disp(['For variable: ',num2str(i),': ',Blabels{i},' r = ',num2str(CCA.predicted_r(i)),', p = ',num2str(CCA.predicted_p(i))])
    p = invprctile(CCA.perm_predicted_r(:,1),CCA.predicted_r(i,1));
    disp([9 'CCA: permutation-based p value for Mode 1: ', num2str(p)])
end

%% Generate group level data from leave one out.

% MCA eigenvalues (just trim them)
MCA.Eigenvalues = MCA.Eigenvalues(:,1:num_comps);

% MCA components in brain space
for comp = 1:num_comps
    data = squeeze(MCA.Varweights(:,comp,:));
    MAT = zeros(size(MCA.index));
    MAT(MCA.index==1) = mean(data,2);
    MCA.VarWeights_MAT(:,:,comp) = MAT;
    
    if strcmp(parc,'voxelwise')==1
        MAT = reshape(MAT,size(lesion_distribution));   %Mode in NII space
        MCA.VarWeights_Nifti(:,:,:,comp) = MAT;
        mat2nii(MAT,[resultsdir,'MCA/Component',num2str(comp),'.nii'],size(lesion_distribution),32,f);
    end
end

% MCA individual weightings
MCA.Indweights_avg = zeros(N,N-2,N);
for i = 1:N
    temp = zeros(N,N-2);
    temp (i,:) = NaN;
    idx =~ isnan(temp);
    temp(idx) = MCA.Indweights(:,:,i);
    MCA.Indweights_avg(:,:,i) = temp;
end
MCA.Indweights_avg = nanmean(MCA.Indweights_avg,3);
% Mode behavioural loadings
%CCA.conload = corr(behaviour,CCA.U);

% Modes in brain space
for Mode = 1:2
    all_data = [];
    
    %CCA will sometimes load in the opposite direction, identify these and
    %flip the weights.
    all_data = CCA.V(:,:,Mode);
    for i = 2:size(all_data,2)
        idx = isnan(all_data(:,1))+ isnan(all_data(:,i));
        r = corr(all_data(~idx,1),all_data(~idx,i));
        
        if r < 0
            all_data(:,i) = all_data(:,i)*-1;
            CCA.V(:,i,Mode) = CCA.V(:,i,Mode)*-1;
            CCA.U(:,i,Mode) = CCA.U(:,i,Mode)*-1;
        end
    end
    
    MAT = zeros(size(MCA.index));
    data = corr(nanmean(all_data,2),MCA.input)';
    MAT(MCA.index==1) = data;
    CCA.Mode_MAT(:,:,Mode) = MAT;
    
    if strcmp(parc,'voxelwise')==1
        MAT = reshape(MAT,size(lesion_distribution));   %Mode in NII space
        CCA.Mode_Nifti(:,:,:,comp) = MAT;
        mat2nii(MAT,[resultsdir,'CCA_Mode',num2str(Mode),'.nii'],size(lesion_distribution),32,f);
    end
    
    CCA.behload(:,Mode) = corr(behav.dataTF,nanmean(CCA.U(:,:,Mode),2));
end

% %% CCA
% % x = behaviours we are interested in (NART,APM,VOSP,CANC,LANG)
% % y = the individual MCA loadings from previous step
%
% disp('--------------------------------------');
% disp('CANONICAL CORRELATION ANALYSIS');
%
% behaviour = behav.dataTF;
% [CCA.A, CCA.B, CCA.R, CCA.U, CCA.V, CCA.stats]=canoncorr(behaviour,MCA.IndWeights);
% disp(['p values for each CCA mode: ',num2str(CCA.stats.p)]);
%
% tmp = corr(CCA.V(:,1),MCA.input)';
% %CCA.EdgeMode = zeros(Node,Node);
% %CCA.EdgeMode(logical(MCA.index)) = tmp*-1;
% save example_modelData.mat CCA
%
% % code for testing:
% X = behaviour;Y=MCA.IndWeights; save LOOdata.mat X Y;clear X Y
% save space_workspace.mat
% CCA.conload = corr(behaviour,CCA.U);
%
% for i = 1:2
%     MAT = zeros(size(MCA.index));
%     data = corr(CCA.V(:,i),MCA.input)';
%     MAT(MCA.index==1) = data;
%     CCA.Mode_MAT(:,:,i) = MAT;
% end
%% Network description analysis
if strcmp(parc,'voxelwise')
    
else
% Nothing complicated, just averaging the CCA loadings within/between each
% network. I calculate this seperately for positive and negative weights,
% as these could average each other out. I also remove non loaded
% connections (i.e. =0) to avoid them influencing the results also.

% Because the CCA has already given weights, its not clear if (or how)
% significance could be calculated. My intuition is that it would be
% double-dipping anyway.

net = Yeo8Index;
for mode = 1:2
    
    cm = CCA.Mode_MAT(:,:,mode);
    cm = cm+cm';
    
    idx = logical(triu(ones(size(cm)),1));
    for pos_neg = 1:2
        if pos_neg==1
            % pos weights only
            new_cm = cm;
            new_cm(new_cm <=0) = NaN;
            
        elseif pos_neg==2
            new_cm = cm;
            new_cm(new_cm >=0) = NaN;
        end
        
        for i = 1:max(net)
            net_i = net==i;
            
            for j = 1:max(net)
                net_j = net==j;
                
                data = new_cm(net_i,net_j);
                data = data(:);
                data(isnan(data)) = [];
                
                if length(data)>50
                    net_value(i,j,pos_neg,mode) = mean(data);
                else
                    net_value(i,j,pos_neg,mode) = NaN;
                end
            end
        end
    end
end
CCA.net_value = net_value;
end

%% Neurosynth decoding
% performed in python, but export the nodes of interest here

%find nodes of interest
for mode=1:2
    cm = CCA.Mode_MAT(:,:,mode);
    cm = cm+cm';

    idx = logical(triu(ones(size(cm)),1));

    for pos_neg = 1:2
        if pos_neg==1
            % pos weights only
            new_cm = cm;
            new_cm(new_cm <=0) = NaN;

        elseif pos_neg==2
            new_cm = cm;
            new_cm(new_cm >=0) = NaN;
        end

        new_cm(isnan(new_cm))=0;
        CCA_degree = sum(abs(new_cm));

        [~,top_CCA_nodes] = sort(CCA_degree,'descend');
        nodes(:,pos_neg,mode) = top_CCA_nodes;
    end
end

CCA.nodes = nodes;

% number of participants with direct (lesion-nii) damage to such nodes?
% interesting for two reasons - show how common this damage is + show that
% the extended rois tend not be damaged as often
% disp('... loading voxelwise data');
%     for p = 1:N
%         f = [DataPath,'lesionMaps/3_rNii/r',P_ID{p},'.nii'];
%         [~,tmp] = read(f);
%         lesionMaps(:,:,:,p) = double(tmp);
%     end
% 
% for i = 1:5
%     node = nodes(i,1);
%     o = [];
%     idx = template==node;
%     idx = idx(:);
%     lesionMaps_2d = reshape(lesionMaps,[size(idx,1),size(lesionMaps,4)]);
%     o = sum(lesionMaps_2d(idx,:),1);
%     disp(['lesion dmg:',num2str(sum(o>0)/size(lesionMaps,4)*100)])
%     
%     o = [];
%     for p = 1:N
%         c = Cdiff(:,:,p)+Cdiff(:,:,p)';
%         o(p) = sum(c(node,:)>0);
%     end
%     o = sum(o>0);
%     disp(['conn dmg:',num2str(o/size(lesionMaps,4)*100)])
% end
%% Save results
close all
diary off
MCA.Varweights = []; %keeps file size small
if strcmp(parc,'voxelwise')
        save([resultsdir,'results.mat'],'CCA','MCA','Cdiff','Cpre','behav')
else
    network_def = Yeo8Index;
    network_labels = {'Vis' 'SomMat' 'DorstAttn' 'SalVentAttn' 'Limbic' 'Control' 'Default' 'SC'};
    save([resultsdir,'results.mat'],'CCA','COG','MCA','Cdiff','Cpre','behav','network_def','network_labels')
end