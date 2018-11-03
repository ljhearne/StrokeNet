% Normative Connectome 'wrapper' script
% explain codes here.
% relies largely upon code from Lead DBS and MTRrix

clearvars
close all
projectdir = '/projects/sw49/';
docsdir = [projectdir,'Project_scripts/'];
addpath(genpath([projectdir,'LEAD']));
addpath([docsdir,'functions']);
%% Inputs

Analysis.datadir = '/scratch/sw49/';  
Analysis.connectomedir = ['/projects/sw49/LEAD/connectomes/dMRI/',...
    'Gibbsconnectome_169 (Horn 2016)/',...
    'data.mat']; %absolute path to the LEAD DBS connectome data
Analysis.lesiondir = [Analysis.datadir,'lesionMaps/3_rNii/']; %coreg lesions

Analysis.conbound = 20; % how many connectomes to include
Analysis.chunkSize = 200; % how many chunks should the data be divided into?
scratch_dir = [Analysis.datadir,'scratch/'];

% read in lead connectome
if exist('Cdata','var')==0
    Cdata = load(Analysis.connectomedir);
end
disp('LeadDBS connectome is in workspace');
%% Organise patient data

% read in spreadsheet of stroke behavioural data.
[NUM,TXT]=xlsread([docsdir,'Stroke_Lucy_030817_edit.xlsx']);
P_ID = TXT(2:end,1); % participant IDs
data = NUM(1:length(P_ID),:);
Patient.age = data(:,4);
Patient.sex = data(:,3); % this is coded backwards
Patient.sex(Patient.sex==0)=2;
Patient.sex = Patient.sex - 1;
Patient.ID = P_ID;

%exlcude participants with missing lesion data.
for subj = 1:length(Patient.ID)
    Analysis.lesionfile = [Analysis.lesiondir,'r',Patient.ID{subj},'.nii'];
    if exist(Analysis.lesionfile,'file')==0
        ex(subj) = 1;
    end
end
ex = find(ex);

Patient.age(ex) = [];
Patient.sex(ex) = [];
Patient.ID(ex)  = [];

clear data key P_ID NUM TXT ex
poolobj = MASSIVEpp(1,scratch_dir);

for subj = 1:length(Patient.ID)
    tic
    
    disp(['Analyzing subj map ',num2str(subj),'/',num2str(length(Patient.ID))]);
    
    %% Normative connectome
    Analysis.ID = Patient.ID{subj};
    Analysis.age = Patient.age(subj);
    Analysis.sex = Patient.sex(subj);
    
    [fibers,Analysis.conboundResult, Analysis.subIDX] = ...
        gen_NormConnectome(Cdata, Analysis.age,Analysis.sex,Analysis.conbound);
    
    % write full normative connectome
    disp('... Writing normative connectome')
    
    tracts = mat2tract(fibers,Analysis.chunkSize,...
        [Analysis.datadir,'temp/'],[Analysis.ID,'_NoLesion']);
    
    % save .tck results
    OUT = [Analysis.datadir,'tracts/conbound',num2str(Analysis.conbound),'/',...
        Analysis.ID,'_NoLesion.tck'];
    write_mrtrix_tracks(tracts,OUT)
    clear tracts
    
    %% Lesioned connectomes
    disp('... Mapping lesion');
    
    Analysis.lesionfile = [Analysis.lesiondir,'r',Analysis.ID,'.nii'];
    
    [Lesion,LesionOnly] = lesion_connectome(fibers,Analysis.lesionfile);
    
    % Write & save fibers
    %lesioned connectome
    disp('... Writing lesioned connectome')
    tracts = mat2tract(Lesion.fibers,Analysis.chunkSize,...
        [Analysis.datadir,'temp/'],[Analysis.ID,'_Lesion']);
    
    OUT = [Analysis.datadir,'tracts/conbound',num2str(Analysis.conbound),'/',...
        Analysis.ID,'_Lesion.tck'];
    write_mrtrix_tracks(tracts,OUT)
    clear tracts
    
    %lesioned tracts only
    try
        disp('... Writing lesioned tracts only')
        tracts = mat2tract(LesionOnly.fibers,Analysis.chunkSize,...
            [Analysis.datadir,'temp/'],[Analysis.ID,'_LesionOnly']);
        
        OUT = [Analysis.datadir,'tracts/conbound',num2str(Analysis.conbound),'/',...
            Analysis.ID,'_LesionOnly.tck'];
        write_mrtrix_tracks(tracts,OUT)
        clear tracts
    catch
    end
    
    % clean up and save analysis details
    
    OUT = [Analysis.datadir,'tracts/conbound',num2str(Analysis.conbound),'/',...
        Analysis.ID,'_details.mat'];
    save(OUT,'Analysis');
    
    toc
    clear fibers
end
MASSIVEpp(0,scratch_dir,poolobj);