function COG = find_centroids(image)

%addpath('/Users/uqlhear2/Documents/MATLAB/x_scripts/');
%addpath('/Users/uqlhear2/Documents/MATLAB/x_toolbox/spm12/');
%requires SPM and read.

[~,data] = read(image);

N = max(max(max(data)));
V = spm_vol(image);
T = V.mat;

for i = 1:N
    
    idx   = double(data == i);
    stats = regionprops(idx);
    cor   = stats.Centroid;
    
    mni = T*[cor(:,1) cor(:,2) cor(:,3) ones(size(cor,1),1)]';
    mni = mni';
    mni(:,4) = [];
    
    COG(i,:) = mni;
end
end 
    