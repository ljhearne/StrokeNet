%function surficeVisbundleVis(MAT,COG,net,Nsize,thresh,out,NIFTI)
%function surficeVisbundleVis(MAT,COG,net,Nsize,thresh,out)
%surficeVis - generates brain vis for StrokeNet project using surfice and
%R. Mofidy this script to change all renderings in the project.
%MAT =node by node matrix
%COG =coordinates (node by 3)
%net =network affilations (or ones)
%size=size of nodes (or ones)
%thresh=lower and upper threshold for edges.
%out = output path and prefix
%NIFTI for surface rendering
% disp(nargin)
% switch nargin
%     case 7
%         DO_SURFACE = 1;
% end
%-----------debug
DO_SURFACE = 1;
MAT = MAT;
COG = COG;
net = Yeo8Index;
Nsize = 500;
thresh = [0,max(max(max(abs(MAT))))];
out = [DocsPath,'Results/CCA/MODEtest'];
NIFTI = [DocsPath,'Results/CCA/Mode1.nii'];
%% Surfice node and edge rendering

% generate NODE and EDGE files
mat2brainnet(MAT,COG,net,Nsize,[out,'.EDGE'],[out,'.NODE']);

edgefile = [out,'.EDGE'];
mesh = '/Applications/Surfice/sample/mni152_2009.mz3';
exe = '/Applications/Surfice/surfice.app/Contents/MacOS/surfice';

%list of commands
BACKCOLOR = 'BACKCOLOR(255, 255, 255);';
MESHLOAD = ['meshload(''',mesh,''');'];
EDGELOAD = ['edgeload(''',edgefile,''');'];
EDGESIZE = 'EDGESIZE(1, true);';
EDGETHRESH = ['EDGETHRESH(',num2str(thresh(1)),',',num2str(thresh(2)),');'];
SHADERXRAY = 'SHADERXRAY(0.50, 0);';
NODETHRESH = 'NODETHRESH(1, 1);';
ORIENT = 'ORIENTCUBEVISIBLE(false);';
%options
CB = 'colorbarvisible(true);';

%plot colorbar for post processing
outfile = [out,'_surficeEdgeAxialColorBar.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    BACKCOLOR,MESHLOAD,EDGELOAD,EDGESIZE,EDGETHRESH,SHADERXRAY,NODETHRESH,...
    ORIENT,CB,'VIEWAXIAL(true);',...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);

% plot three angles
VIEW{1} = 'VIEWAXIAL(true);';
VIEW{2} = 'VIEWSAGITTAL(true);';
VIEW{3} = 'VIEWSAGITTAL(true);AZIMUTH(180);';

clear outfile
outfile{1} = [out,'_surficeEdgeAxial.bmp'];
outfile{2} = [out,'_surficeEdgeRight.bmp'];
outfile{3} = [out,'_surficeEdgeLeft.bmp'];
CB = 'colorbarvisible(false);';
for i = 1:3
    cmd = [exe,' -S "begin RESETDEFAULTS;',...
        BACKCOLOR,MESHLOAD,EDGELOAD,EDGESIZE,EDGETHRESH,SHADERXRAY,NODETHRESH,...
        ORIENT,CB,VIEW{i},...
        'SAVEBMP(''',outfile{i},''');',...
        'quit;',...
        'end."'];
    system(cmd);
end

%% Surface in Surfice!

if DO_SURFACE ==1
    clear VIEW
    VIEW = 'AZIMUTHELEVATION(70, 15);';
    OVERLAY = ['OVERLAYLOAD(''',NIFTI,''');'];
    THRESH = ['OVERLAYMINMAX(''',1,thresh(2)*-1,thresh2,''');'];
    ALPHA = 'OVERLAYTRANSPARENCYONBACKGROUND(25);';
    
    clear outfile
    outfile = [out,'test.bmp'];
    cmd = [exe,' -S "begin RESETDEFAULTS;',...
        VIEW,BACKCOLOR,MESHLOAD,OVERLAY,THRESH,ALPHA...
        ORIENT,CB,VIEW,...
        'SAVEBMP(''',outfile,''');',...
        'end."'];
    system(cmd);

end

%% EDGE BUNDLING IN R
%debug---
labels = {'net1','net2','net3','net4','net5','net6','net7','net8','net8','net9','net10'};
%debug---

%re-interpret label indicies by hemisphere
netN = length(labels);
labels2 = flipud(labels);
newlabels = [labels;labels2];
for i = 1:netN 
    newlabels{i} = horzcat(newlabels{i},'_right');
    newlabels{i+netN }...
        = horzcat(newlabels{i+netN },'_left');
end

% split COG by left/right
idx = netN + fliplr(1:netN);
for i = 1:size(COG,1)
    if COG(i,1) < 0
        newnet(i) = idx(net(i));
    else
        newnet(i) = net(i);
    end
end
labels = newlabels;
net = newnet;

% sort COG and network by new order
[~,idx] = sort(net);
net = net(idx);
COG = COG(idx,:);
    
% generate inner hierarchy
from = repmat({'origin'},size(labels));
to = labels;
T = table(from,to);
outfile = [out,'_Bundle1.csv'];
writetable(T,outfile);
clearvars to from T

% generate outer hierarchy (node level)
deg = sum(abs(MAT)+abs(MAT'));
T = table(deg);
outfile = [out,'_deg.csv'];
writetable(T,outfile);

for i = 1:size(COG,1)
    from{i,1} = labels(Yeo8Index(i));
    to{i,1} = horzcat('node_',num2str(i));
    %value(i,1) = deg(i);
end
T = table(from,to);
outfile = [out,'_Bundle2.csv'];
writetable(T,outfile);
clearvars to from T value

% generate matrix file (edge level)
MATbin = MAT~=0;
[fromIDX,toIDX] = ind2sub(size(MATbin),find(MATbin));
for i = 1:size(toIDX,1)
    from{i,1} = horzcat('node_',num2str(fromIDX(i)));
    to{i,1} = horzcat('node_',num2str(toIDX(i)));
    value(i,1) = MAT(fromIDX(i),toIDX(i));
end
T = table(from,to,value);
outfile = [out,'_MAT.csv'];
writetable(T,outfile);
