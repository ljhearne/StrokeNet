% 
clearvars
close all

addpath('/projects/sw49/NifTI/');
addpath('/projects/sw49/Project_scripts/functions/');
nii = '512inMNI_plus_AAL.nii'
[COG, rois] = extract_roi(nii);

save 538COG.mat COG
