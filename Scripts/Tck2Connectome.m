% generate connectomes
clearvars
close all
addpath('functions');
basedir = '/scratch/sw49/1_LEADStrokeMapping/';

%parc = [basedir,'Atlas/512inMNI.nii'];
%parc = [basedir,'Atlas/512inMNI_plus_AAL.nii'];
parc = [basedir,'Atlas/Schaefer200_plus_HOAAL.nii'];
%parc = [basedir,'Atlas/Schaefer100_plus_HO.nii'];

parcLabel = '240/'; % label for parcellation
path2tracts = [basedir,'tracts_conbound20/'];
outpath = 'connectomes_conbound20/';
[~, ~, P_ID] = load_stroke_behav;
sep = ' ';

for i = 1:length(P_ID)
    try
        %% No lesion
        load([path2tracts,P_ID{i},'_NoLesion.mat'])
        disp([path2tracts,P_ID{i},'_NoLesion.mat'])
        infile = [path2tracts,P_ID{i},'_NoLesion.tck'];
        outfile = [basedir,outpath,parcLabel,Analysis.ID,Analysis.postName,'.csv'];
        outfile2 = [basedir,outpath,parcLabel,Analysis.ID,Analysis.postName,'streamAssignment.txt'];
        
        system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2]);
        clear infile outfile outfile2 Analysis
        
        %% Lesion
        % load the analysis file
        load([path2tracts,P_ID{i},'_Lesion.mat'])
        disp([path2tracts,P_ID{i},'_Lesion.mat'])
        infile = [path2tracts,P_ID{i},'_Lesion.tck'];
        outfile = [basedir,outpath,parcLabel,Analysis.ID,Analysis.postName,'.csv'];
        outfile2 = [basedir,outpath,parcLabel,Analysis.ID,Analysis.postName,'streamAssignment.txt'];
        
        system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2]);
        clear infile outfile outfile2 Analysis
        
    catch me
        disp([P_ID{i},' failed']);
    end
end