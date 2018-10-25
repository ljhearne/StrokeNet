% generate connectomes
clearvars
close all

datadir = '/scratch/sw49/';
docsdir = '/projects/sw49/';
addpath([docsdir,'Project_scripts/functions']);
%% Inputs
%parcellation choice
parc = [docsdir,'Atlas/rSchaefer200_plus_HOAAL.nii'];
parcLabel = 'r240/'; % label for parcellation
conbound = 15;

%%

tractsdir = [datadir,'tracts/conbound',num2str(conbound),'/'];
outpath = [datadir,'connectomes/conbound',num2str(conbound),'/'];
[~, ~, P_ID] = load_stroke_behav;
sep = ' ';

mkdir([outpath,parcLabel]);

for i = 1:length(P_ID)
    try
        % ensure files exist
        load([tractsdir,P_ID{i},'_details.mat'])
        disp([tractsdir,P_ID{i},'_details.mat'])
        
        %% No lesion
        type = '_NoLesion';
        infile = [tractsdir,P_ID{i},type,'.tck'];
        outfile = [outpath,parcLabel,Analysis.ID,type,'.csv'];
        outfile2 = [outpath,parcLabel,Analysis.ID,type,'streamAssignment.txt'];
        
        tmp = system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2]);
        clear infile outfile outfile2
        
        %% Lesion
        type = '_Lesion';
        infile = [tractsdir,P_ID{i},type,'.tck'];
        outfile = [outpath,parcLabel,Analysis.ID,type,'.csv'];
        outfile2 = [outpath,parcLabel,Analysis.ID,type,'streamAssignment.txt'];
        
        tmp = system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2]);
        clear infile outfile outfile2 Analysis
        
    catch me
        disp([P_ID{i},' failed']);
        disp(me)
    end
end