clearvars
close all

DataPath = '/Users/luke/Documents/Projects/StrokeNet/Data/';
DocsPath = '/Users/luke/Documents/Projects/StrokeNet/Docs/';

addpath('functions');
%add path to BCT

%% inputs
dataType = 'conbound15/'; %data type
parcLabel = '240'; % label for parcellation
behav.variables = [3,4,8,10,11,12,70,31]; % see 'key' variable for further info.

% load data
load([DocsPath,'Atlas/',parcLabel,'COG.mat']); % atlas COG
load([DocsPath,'Atlas/',parcLabel,'parcellation_Yeo8Index.mat']);


[~,template] = read([DocsPath,'Atlas/Schaefer200_plus_HOAAL']); %link to template
parc = zeros(size(template));
for i = 5%1:max(Yeo8Index)
    
    idx = Yeo8Index==i;
    idx = find(idx);
    
    for j = 1:length(idx)
        new_idx = template==idx(j);
        parc(new_idx) = i;
    end
end

mat2nii(parc,[DocsPath,'Results/parc.nii'],size(parc),32,[DocsPath,'Atlas/Schaefer100_plus_HOAAL'])
