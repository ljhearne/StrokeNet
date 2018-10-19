function [MCA,PCA] = run_MCA(Cdiff,lesion_affection,comps,DocsPath)
%Function that takes some lesion connectivity and does an MCA.
% Lesion weights are treated as binary (i.e. missing or not).
%The R code is hard-coded regarding some paths (I don't know of a way to
% pass arguments from matlab to R).
%
%run_MCA(Cdiff,lesion_affection,comps,DocsPath)
% Cdiff = lesion difference maps (node x node x subj);
%
% lesion_affection = how many participants need to be lesioned at this edge
% for it to be included? Analagous to lesion affection in VLSM.
%
% comps = number of components to extract in the MCA. Usually set to the
% same amount of behavioural variables (rule of thumb)
%
%DocsPath = project specific format of saving the output files

SampSize = size(Cdiff,3);

% organise the connectivity weights
MCA.Connindex = sum(Cdiff>0,3)>lesion_affection; %index informative voxels
for i = 1:SampSize
    tmp = Cdiff(:,:,i)>0; %binarize
    MCA.Conn(i,:) = tmp(MCA.Connindex);
end
disp([num2str(length(MCA.Conn)),' connections considered in MCA']);

% Performs MCA via R.
csvwrite([DocsPath,'Results/MCA/MCAinput.csv'],double(MCA.Conn));
csvwrite([DocsPath,'Results/MCA/MCAcomp.csv'],[0,0;0,double(comps)]);

%system('Rscript MCAR.R')
system('/Library/Frameworks/R.framework/Versions/3.5/Resources/bin/Rscript MCAR.R');
MCA.VarWeights = csvread([DocsPath,'Results/MCA/MCA_VarWeights.csv'],1,1);
MCA.Eigen = csvread([DocsPath,'Results/MCA/MCA_Eigenvalues.csv'],1,1);
MCA.IndWeights = csvread([DocsPath,'Results/MCA/MCA_IndWeights.csv'],1,1);
% from what I can tell the lesion loadings are represented on every SECOND
% row (i.e. 2:2) the other rows represent the "non-lesion loadings"
MCA.VarWeightsE = MCA.VarWeights(2:2:end,:);

%% PCA
% also calculates PCA by weighting each lesion by the sqrt of the degree
% (similar to Zhang et al., 2014 in spirit).
PCA.Connindex = sum(Cdiff>0,3)>lesion_affection; %index informative voxels
for i = 1:SampSize
    tmp = Cdiff(:,:,i)>0; %binarize
    tmp = tmp/(sqrt(sum(sum(tmp)))); %normalize by sum of lesion.
    PCA.Conn(i,:) = tmp(PCA.Connindex);
end

[PCA.coeff,PCA.score] = pca(PCA.Conn);
end

