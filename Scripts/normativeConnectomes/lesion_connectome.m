function [Lesion,LesionOnly] = lesion_connectome(fibers,path2lesionfile)
%lesion_connectome
%   This function takes the tract information and the lesion information
%   and either subtracts it from the tracts (i.e. a lesioned connectome) OR
%   just writes the lesioned tracts (which may be useful for visualisation
%   purposes or some other analysis. Almost all the code contained within
%   this function is directly from LEAD DBS and thus should be credited to
%   those that contributed to that project (Andreas Horn).
% INPUTS:
%fibers
%path2lesionfile = the path to the nifti containing a lesion map of 1s & 0s
%map_lesion = indicates the type of analysis

tree=KDTreeSearcher(fibers(:,1:3));

Vseed=ea_load_nii(path2lesionfile); %load the nifti
lesionsize = sum(sum(sum(Vseed.img)));

% create vector of x,y,z coordinates related to the seed.
maxdist=mean(abs(Vseed.voxsize))/2;
Vseed.img(isnan(Vseed.img))=0;
idx=find(Vseed.img); %indices of seed region
ixvals=Vseed.img(idx); %the same as ids... as vals are 1
[xx,yy,zz]=ind2sub(size(Vseed.img),idx); %x,y,z values in voxel space
XYZvx=[xx,yy,zz,ones(length(xx),1)]'; % now in a single vector
XYZmm=Vseed.mat*XYZvx; %transpose into mm/connectome space!
XYZmm=XYZmm(1:3,:)';
clear idx Vseed

ids=rangesearch(tree,XYZmm,maxdist,'distance','chebychev');
%ixdim=length(ixvals);
fiberstrength=zeros(max(fibers(:,4)),1); % in this var we will store a mean value for each fiber (not fiber segment) traversing through seed
fiberstrengthn=zeros(max(fibers(:,4)),1);

for i=find(cellfun(@length,ids))'
    % assign fibers on map with this weighted value.
    fibnos=unique(fibers(ids{i},4)); % these fiber ids go through this particular voxel.
    fiberstrength(fibnos)=fiberstrength(fibnos)+ixvals(i);
    fiberstrengthn(fibnos)=fiberstrengthn(fibnos)+1;
end

idx=~(fiberstrength==0);
fiberstrength(idx)=fiberstrength(idx)./fiberstrengthn(idx); % now each fiber has a strength mediated by the seed.

idx = ismember(fibers(:,4),find(fiberstrength));
% normative connectome - lesion
Lesion.fibers = fibers;
Lesion.fibers(idx,:) = [];

% lesion only
LesionOnly.fibers = fibers;
LesionOnly.fibers = fibers(idx,:);
end

