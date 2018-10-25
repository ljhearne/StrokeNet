function surficeVisbundleVis(MAT,COG,net,size,thresh,out)
%function surficeVisbundleVis(MAT,COG,net,size,thresh,out)
%surficeVis - generates brain vis for StrokeNet project using surfice and
%R. Mofidy this script to change all renderings in the project.
%MAT =node by node matrix
%COG =coordinates (node by 3)
%net =network affilations (or ones)
%size=size of nodes (or ones)
%thresh=threshold for edges;
%out = output path and prefix

%--------------------
% %debugging
% MAT=rMAT;
% COG=COG;
% net=Yeo8Index;
% size = ones(length(COG),1);
% thresh = [0.5,1];
% out = [DocsPath,'Results/SanityCheck/AgeCorr'];
%--------------------
% generate NODE and EDGE files
mat2brainnet(MAT,COG,net,size,[out,'.EDGE'],[out,'.NODE']);

%% surfice rendering
edgefile = [out,'.EDGE'];
mesh = '/Applications/Surfice/sample/mni152_2009.mz3';
exe = '/Applications/Surfice/surfice.app/Contents/MacOS/surfice';

%plot 1a
outfile = [out,'_surficeAxial.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    'BACKCOLOR(255, 255, 255);',...
    'meshload(''',mesh,''');',...
    'edgeload(''',edgefile,''');',...
    'EDGESIZE(1, true);',...
    'EDGETHRESH(',num2str(thresh(1)),',',num2str(thresh(2)),');',...
    'SHADERXRAY(0.50, 0.50);',...
    'NODETHRESH(1, 1);',...
    'colorbarvisible(false);',...
    'VIEWAXIAL(true);',...
    'ORIENTCUBEVISIBLE(false);',...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);

%plot 1b
outfile = [out,'_surficeAxial_det.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    'BACKCOLOR(255, 255, 255);',...
    'meshload(''',mesh,''');',...
    'edgeload(''',edgefile,''');',...
    'EDGESIZE(1, true);',...
    'EDGETHRESH(',num2str(thresh(1)),',',num2str(thresh(2)),');',...
    'SHADERXRAY(0.50, 0.50);',...
    'NODETHRESH(1, 1);',...
    'colorbarvisible(true);',...
    'VIEWAXIAL(true);',...
    'ORIENTCUBEVISIBLE(true);',...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);

%plot 2
outfile = [out,'_surficeRight.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    'BACKCOLOR(255, 255, 255);',...
    'meshload(''',mesh,''');',...
    'edgeload(''',edgefile,''');',...
    'EDGESIZE(1, true);',...
    'EDGETHRESH(',num2str(thresh(1)),',',num2str(thresh(2)),');',...
    'SHADERXRAY(0.50, 0.50);',...
    'NODETHRESH(1, 1);',...
    'colorbarvisible(false);',...
    'VIEWSAGITTAL(true);',...
    'ORIENTCUBEVISIBLE(false);',...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);

%plot 3
outfile = [out,'_surficeLeft.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    'BACKCOLOR(255, 255, 255);',...
    'meshload(''',mesh,''');',...
    'edgeload(''',edgefile,''');',...
    'EDGESIZE(1, true);',...
    'EDGETHRESH(',num2str(thresh(1)),',',num2str(thresh(2)),');',...
    'SHADERXRAY(0.50, 0.50);',...
    'NODETHRESH(1, 1);',...
    'colorbarvisible(false);',...
    'VIEWSAGITTAL(true);',...
    'AZIMUTH(180);',...
    'ORIENTCUBEVISIBLE(false);',...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);