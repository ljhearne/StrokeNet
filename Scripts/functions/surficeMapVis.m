function surficeMapVis(NIFTI,thresh,out)

mesh = '/Applications/Surfice/sample/mni152_2009.mz3';
exe = '/Applications/Surfice/surfice.app/Contents/MacOS/surfice';

%list of commands
BACKCOLOR = 'BACKCOLOR(255, 255, 255);';
MESHLOAD = ['meshload(''',mesh,''');'];
ORIENT = 'ORIENTCUBEVISIBLE(false);';

%options
CB = 'colorbarvisible(true);';
OVERLAY = ['OVERLAYLOAD(''',NIFTI,''');'];
COLOR = 'OVERLAYCOLORNAME(1,''ACTC'');';
THRESH = ['OVERLAYMINMAX(',num2str(1),',',num2str(thresh*-1),',',num2str(thresh),');'];
ALPHA = 'OVERLAYTRANSPARENCYONBACKGROUND(25);';

clear view
VIEW{1} = 'VIEWAXIAL(true);';
VIEW{2} = 'AZIMUTHELEVATION(120, 15);';
VIEW{3} = 'AZIMUTHELEVATION(-120, 15);';

% draw color bar first
outfile = [out,'test.bmp'];
cmd = [exe,' -S "begin RESETDEFAULTS;',...
    VIEW{1},BACKCOLOR,MESHLOAD,OVERLAY,THRESH,COLOR,ALPHA...
    'SAVEBMP(''',outfile,''');',...
    'quit;',...
    'end."'];
system(cmd);

% draw 3 views
clear outfile
outfile{1} = [out,'_surficeMapAxial.bmp'];
outfile{2} = [out,'_surficeMapRight.bmp'];
outfile{3} = [out,'_surficeMapLeft.bmp'];
for i = 1:3
    cmd = [exe,' -S "begin RESETDEFAULTS;',...
        VIEW{i},BACKCOLOR,MESHLOAD,OVERLAY,THRESH,COLOR,ALPHA...
        'SAVEBMP(''',outfile{i},''');',...
        'quit;',...
        'end."'];
    system(cmd);
end
end


