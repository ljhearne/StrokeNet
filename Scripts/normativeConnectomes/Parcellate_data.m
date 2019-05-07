% generate connectomes
clearvars
close all
%addpath([docsdir,'Project_scripts/functions']);

%% Inputs
conbound = 20;
datadir = '/scratch/sw49/';
docsdir = '/projects/sw49/';
scratch_dir = [datadir,'scratch/'];
tractsdir = [datadir,'tracts/conbound',num2str(conbound),'/'];
%FCdir = [datadir,'NKIGibs_func/'];
outpath = [datadir,'connectomes/conbound',num2str(conbound),'/'];

%parcellation choice
parc = [docsdir,'atlas/rSchaefer200_plus_HO.nii'];
parcLabel = 'Sch214/'; % label for parcellation
%[hdr,nki_space] = read([docsdir,'atlas/node_definitions182.nii']);
%nki_space = round(nki_space);%due to possible downsampling

%read in the atlas
[~,parc_space]= read(parc);
parc_space = round(parc_space); %due to possible downsampling
nRoi = max(max(max(parc_space)));

%%
[~, ~, P_ID] = load_stroke_behav;
sep = ' ';
mkdir([outpath,parcLabel]);

%poolobj = MASSIVEpp(1,scratch_dir);

for i = 1:length(P_ID)
    tic
    try
        
        %% SC
        % ensure files exist
        load([tractsdir,P_ID{i},'_details.mat'])
        disp([tractsdir,P_ID{i},'_details.mat'])
        
        %% No lesion
        type = '_NoLesion';
        infile = [tractsdir,P_ID{i},type,'.tck'];
        outfile = [outpath,parcLabel,Analysis.ID,type,'_SC'];
        outfile2 = [outpath,parcLabel,Analysis.ID,type,'streamAssignment_SC.txt'];
        
        tmp = system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2,' &>/dev/null']);
        
        %% Lesion
        type = '_Lesion';
        infile = [tractsdir,P_ID{i},type,'.tck'];
        outfile = [outpath,parcLabel,Analysis.ID,type,'_SC'];
        outfile2 = [outpath,parcLabel,Analysis.ID,type,'streamAssignment_SC.txt'];
        
        tmp = system(['./gen_connectome.sh ',infile,sep,parc,sep,outfile,sep,outfile2]);
        
%         %% FC
%         
%         nki_subs = Analysis.subIDX;
%         
%         parfor j = 1:length(nki_subs)
%             tmp = load([FCdir,'0',num2str(nki_subs(j)),'_func_TC.mat']);
%             
%             %create mean signal for each parc roi
%             parc_timeseries = zeros(nRoi,size(tmp.func_TC,1));
%             for roi = 1:nRoi
%                 %roi in parcellation space
%                 parc_roi = parc_space==roi;
%                 % what 44k rois match to template?
%                 nki_roi = unique(nki_space(parc_roi));
%                 % remove any 0/Nan indices
%                 nki_roi(nki_roi==0) = [];
%                 nki_roi(isnan(nki_roi)) = [];
%                 
%                 parc_timeseries(roi,:) = mean(tmp.func_TC(:,nki_roi),2);
%             end
%             
%             FC_mat(:,:,j) = corr(parc_timeseries');
%             
%         end
%         
%         %average FC across NKI participants
%         FC = nanmean(FC_mat,3);
%         % save the data
%         outfile = [outpath,parcLabel,P_ID{i},'_NoLesion_FC.mat'];
%         save(outfile,'FC');
        
    catch me
        disp([P_ID{i},' failed']);
        disp(me)
    end
    
    disp([ 9 P_ID{i},' finished'])
    disp([ 9 'time elapsed: ' num2str(round(toc,1))])
end

%MASSIVEpp(0,scratch_dir,poolobj);