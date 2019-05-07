function [MCA,PCA] = run_MCA(Cvec,lesionAffection,DocsPath)
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
%DocsPath = project specific format of saving the output files

%remove any old MCA files
system('rm /Users/luke/Documents/Projects/StrokeNet/Docs/Results/MCA/MCA*');

% organise the connectivity weights
MCA.index = sum(Cvec)>lesionAffection; %index informative voxels
MCA.input = Cvec(:,MCA.index);
disp([num2str(length(MCA.input)),' variables considered in MCA']);

% Performs MCA via R.
csvwrite([DocsPath,'Results/MCA/MCAinput.csv'],double(MCA.input));
csvwrite([DocsPath,'Results/MCA/MCAcomp.csv'],[0,0;0,double(100)]);

%system('Rscript MCAR.R')
system('/Library/Frameworks/R.framework/Versions/3.4/Resources/bin/Rscript MCAR.R');
MCA.VarWeights = csvread([DocsPath,'Results/MCA/MCA_VarWeights.csv'],1,1);
MCA.Eigen = csvread([DocsPath,'Results/MCA/MCA_Eigenvalues.csv'],1,1);
MCA.IndWeights = csvread([DocsPath,'Results/MCA/MCA_IndWeights.csv'],1,1);

% The lesion loadings are represented on every SECOND
% row (i.e. 2:2) the other rows represent the "non-lesion loadings". See
% https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3718710/ table 5
MCA.VarWeightsE = MCA.VarWeights(2:2:end,:);
end

