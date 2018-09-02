% Lead to MRTrix function
% explain codes here.
% relies largely upon code from Lead DBS and MTRrix

clearvars
close all

addpath(genpath('/projects/sw49/LEAD'));
addpath('functions');
%% Inputs

Analysis.basedir = '/scratch/sw49/1_LEADStrokeMapping/';
Analysis.path2connectome = ['/projects/sw49/LEAD/connectomes/dMRI/',...
    'Gibbsconnectome_169 (Horn 2016)/',...
    'data.mat']; %absolute path to the LEAD DBS connectome data
Analysis.path2lesionmaps = [Analysis.basedir,'Lesions/'];

Analysis.con = 1; % 1 = connectivity based selection, 2 = age based selection;
Analysis.agebound = ''; % how many +- years for normative connectome?
Analysis.conbound = 5; % how many connectomes to include
Analysis.chunkSize = 200; % how many chunks should the data be divided into?
map_lesion = 0;
scratch_dir = '/scratch/sw49/scratch';

if map_lesion == 1
    Analysis.postName = '_Lesion';
elseif map_lesion == 2
    Analysis.postName = '_LesionOnly';
elseif map_lesion == 0
    Analysis.postName = '_NoLesion';
end

%% LEAD CONNECTOME

% read in lead connectome
if exist('Cdata','var')==0
    Cdata = load(Analysis.path2connectome);
end

% loop through lesion maps.
[data, ~, P_ID] = load_stroke_behav;
Patient.age = data(:,4);
Patient.sex = data(:,3);
Patient.ID = P_ID;
clear data key P_ID

for lesion = 1:length(Patient.ID)
    tic
    data = Cdata;
    streamIDX = [];
    streamIDX = unique(data.fibers(:,4));
    
    disp(['Analyzing lesion map ',Patient.ID{lesion}]);
    Analysis.ID = Patient.ID{lesion};
    Analysis.lesionfile = [Analysis.path2lesionmaps,Analysis.ID,'_interp.nii'];
    if exist(Analysis.lesionfile,'file')==0
        disp('Lesion Nifti not located');
        continue
    end
    
    Analysis.age = Patient.age(lesion);
    Analysis.sex = Patient.sex(lesion);
    
    % GENDER
    idx = data.sex==Analysis.sex;
    data.age = data.age(idx);
    data.sub = data.sub(idx);
    streamIDX = streamIDX(idx);
    
    % AGE
    if Analysis.con == 1
        [idxsub,idx] = unique(data.sub);
        ageidx = data.age(idx);
        
        [tmp,idx] = sort(abs(ageidx - Analysis.age),'ascend');
        idx = idxsub(idx(1:Analysis.conbound));
        idx2 = ismember(data.sub,idx);
        
        Analysis.conboundResult = tmp(Analysis.conbound);
        
    elseif Analysis.con == 0
        idx2 = data.age<= Analysis.age+Analysis.agebound ...
            & data.age >= Analysis.age-Analysis.agebound;
    end
    
    streamIDX = streamIDX(idx2);
    Analysis.subIDX = unique(data.sub(idx2));
    
    disp(['...including ',num2str(length(Analysis.subIDX)),' unique connectomes']);
    
    % remove fibers that are not needed
    idx = ismember(data.fibers(:,4),streamIDX);
    fibers = data.fibers(idx,:);
    streamIDX = unique(fibers(:,4)); %redudant
    
    clear idx* data
    
    %% Lesion tracts
    
    if map_lesion > 0;
        disp('Mapping lesion');
        [fibers,streamIDX,lesionsize] = lesion_connectome...
            (fibers,Analysis.lesionfile,map_lesion);
    end
    
    %% Write fibers

    poolobj = MASSIVEpp(1,scratch_dir); % server requires specific code to 
    % open a parpool - not needed otherwise.
    
    disp('...Writing temporary fibers')
    tract = mat2tract(fibers,streamIDX,Analysis.chunkSize,...
        [Analysis.basedir,'temp/'],[Analysis.ID,'_',Analysis.postName]);
    MASSIVEpp(0,scratch_dir,poolobj);
    
    % save results
    OUT = [Analysis.basedir,'tracts/',Analysis.ID,Analysis.postName,'.tck'];
    write_mrtrix_tracks(tract,OUT)
    
    %save analysis structure
    OUT = [Analysis.basedir,'tracts/',Analysis.ID,Analysis.postName,'.mat'];
    save(OUT,'Analysis');
    
    toc 
end


