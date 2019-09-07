% Surface visualisation script
clearvars
close all

% addpath('/Applications/workbench/bin_macosx64/');
% %addpath('/Users/luke/Documents/Projects/StrokeNet/Data/gifti-1.8')
% 
% input_volume = '/Users/luke/Documents/Projects/StrokeNet/Docs/Results/conbound20/Sch240/CCA_Mode1.nii';
% 
% %midthick
% disp(['./wb_command -volume-to-surface-mapping ',input_volume,' /Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/Conte69_atlas_164k_wb/Conte69.L.midthickness.164k_fs_LR.surf.gii ',input_volume,'_L.shape.gii -trilinear']);
% disp(['./wb_command -volume-to-surface-mapping ',input_volume,' /Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/Conte69_atlas_164k_wb/Conte69.R.midthickness.164k_fs_LR.surf.gii ',input_volume,'_R.shape.gii -trilinear']);

%%

% filename for the template we'll make  
template_fname = 'template.pscalar.nii';  

path2templates ='/Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/32k_ConteAtlas_v2/';
path2sch = '/Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/Schaefer200/';
path2result = '/Users/luke/Documents/Projects/StrokeNet/Docs/Results/';
path2CCAvector1 = '/Users/luke/Documents/Projects/StrokeNet/Docs/Results/conbound20/Sch240/CCA_Mode1_vector.txt';
path2CCAvector2 = '/Users/luke/Documents/Projects/StrokeNet/Docs/Results/conbound20/Sch240/CCA_Mode2_vector.txt';

% make a template pscalar.nii from the MMP atlas  
 disp(['./wb_command -cifti-parcellate ', path2sch,'Schaefer2018_200Parcels_7Networks_order.dscalar.nii ',...   
        path2sch, 'Schaefer2018_200Parcels_7Networks_order.dlabel.nii COLUMN ',... 
        path2result, template_fname]);  
   
% you can make a text version of the template, which has 360 rows, but the values in each row aren't the parcel numbers.  
disp(['./wb_command -cifti-convert -to-text ', path2result, template_fname, ' ', path2result, 'temp.txt']);  

%  create a CIFTI from the text file for viewing in Workbench
disp(['./wb_command -cifti-convert -from-text ', path2CCAvector1,' ', path2result, template_fname, ' ', path2result, 'CCA_mode1.pscalar.nii']);  
disp(['./wb_command -cifti-convert -from-text ', path2CCAvector2,' ', path2result, template_fname, ' ', path2result, 'CCA_mode2.pscalar.nii']);  
%  if (!file.exists(paste0(local.path, "plotDemo.pscalar.nii"))) { stop(paste("missing:", local.path, "plotDemo.pscalar.nii")); }  