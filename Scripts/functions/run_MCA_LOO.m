function [MCA,PCA] = run_MCA_LOO(Cvec,lesionAffection,resultsdir,run_MCA)
%Function that takes some lesion connectivity and does an MCA.
% Lesion weights are treated as binary (i.e. missing or not).
%The R code is hard-coded regarding some paths (I don't know of a way to
% pass arguments from matlab to R).
%
%run_MCA(Cdiff,lesion_affection,DocsPath)
% Cvec = matrix of where the damge is (subj by location)
%
% lesionAffection = how many participants need to be lesioned at this edge
% for it to be included? Analagous to lesion affection in VLSM.
%
%

%Path = project specific format of saving the intermediate output files
Path = '/Users/luke/Documents/Projects/StrokeNet/Data/MCA/';

% organise the connectivity weights
MCA.index = sum(Cvec)>lesionAffection; %index informative voxels
MCA.input = Cvec(:,MCA.index);
disp([num2str(length(MCA.input)),' variables considered in MCA']);

if run_MCA==1
    %remove any old MCA files
    system(['rm ',Path,'MCA*']);
    
    % organise the R inputs
    csvwrite([Path,'MCAinput.csv'],double(MCA.input));
    csvwrite([Path,'MCAcomp.csv'],[0,0;0,double(100)]);
    
    % Performs MCA via R.
    %system('Rscript MCAR.R')
    system('/Library/Frameworks/R.framework/Versions/3.4/Resources/bin/Rscript MCAR_LOO.R');
    
    % load in the data and save to .mat file in results directory
    for subj = 1:size(MCA.input,1)
        Indweights(:,:,subj)   = csvread([Path,'MCA_IndWeights_LO',num2str(subj),'.csv'],1,1);
        LOO_Indweights(subj,:) = csvread([Path,'MCA_LO',num2str(subj),'_vec.csv'],1,1);
        temp = [];
        temp                   = csvread([Path,'MCA_Eigenvalues_LO',num2str(subj),'.csv'],1,1);
        Eigenvalues(subj,:)    = temp(:,1);
        temp = [];
        temp                   = csvread([Path,'MCA_VarWeights_LO',num2str(subj),'.csv'],1,1);
        Varweights(:,:,subj)   = temp(2:2:end,:);
    end
    save([resultsdir,'MCA/Weights.mat'],'Indweights','LOO_Indweights','Eigenvalues','Varweights')
    
    % clean up the directory
    %system(['rm ',Path,'MCA*']);
end

% load in the data and save to MCA structure
temp = load([resultsdir,'MCA/Weights.mat']);
MCA.Indweights = temp.Indweights;
MCA.LOO_Indweights = temp.LOO_Indweights;
MCA.Eigenvalues = temp.Eigenvalues;
MCA.Varweights = temp.Varweights;
end

