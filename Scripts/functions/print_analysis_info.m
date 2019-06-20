function print_analysis_info(P_ID,demo_data,parc,Cpre,Cpost,conbound)
% print and save basic participant and connectome information
% assumes demo_data =  demographic variables (age,gender,education,chronicity)
% includes hard coding - 

disp([num2str(length(P_ID)),' participants']);
disp([num2str(sum(demo_data(:,2))),' males'])
disp(['Mean age = ',num2str(mean(demo_data(:,1))),...
    ', std = ',num2str(std(demo_data(:,1))),...
    ', range = ',num2str(min(demo_data(:,1))),...
    ' - ',num2str(max(demo_data(:,1)))]);
disp(['Mean education = ',num2str(mean(demo_data(:,2))),...
    ', std = ',num2str(std(demo_data(:,2))),...
    ', range = ',num2str(min(demo_data(:,2))),...
    ' - ',num2str(max(demo_data(:,2)))]);

disp(['Mean chronicity = ',num2str(mean(demo_data(:,3))),...
    ', std = ',num2str(std(demo_data(:,3))),...
    ', range = ',num2str(min(demo_data(:,3))),...
    ' - ',num2str(max(demo_data(:,3)))]);

%% Information about normative connectomes
nki_data = load(['/Users/luke/Documents/Projects/StrokeNet/Data/NKIdetails.mat']);
Cdata = nki_data.Cdata;
[sublabel,subidx] = unique(Cdata.sub);
NKIage = Cdata.age(subidx);
NKIsex = Cdata.sex(subidx);

% Connectomic age
for i = 1:length(P_ID)
       
    % load analysis information
    AI = load(['/Users/luke/Documents/Projects/StrokeNet/Data/','tracts/',conbound,P_ID{i},'_details.mat']);
    
    for j = 1:length(AI.Analysis.subIDX)
        idx = AI.Analysis.subIDX(j)== Cdata.sub;
        tmp(j) = max(Cdata.age(idx));
    end
    
    ConnectomeAge.raw{i} = tmp;
    ConnectomeAge.range(i,1) = min(ConnectomeAge.raw{i});
    ConnectomeAge.range(i,2) = max(ConnectomeAge.raw{i});
    ConnectomeAge.range(i,3) = ConnectomeAge.range(i,2)-ConnectomeAge.range(i,1);
    ConnectomeAge.mean(i) = mean(ConnectomeAge.raw{i});
    ConnectomeAge.diff(i) = abs(ConnectomeAge.mean(i)-demo_data(i,1));
end

disp(['Average range of connectomes = ',num2str(mean(ConnectomeAge.range(:,3))),...
    ', std = ',num2str(std(ConnectomeAge.range(:,3))),...
    ' and distance to actual age = ',num2str(mean(ConnectomeAge.diff))]);

% connectome density
if strcmp(parc,'voxelwise')==0
    Node = size(Cpre,1);
    NodeTotal = (Node*(Node-1))/2;
    
    for i = 1:length(P_ID)
        density.pre(i) = sum(sum(Cpre(:,:,i)>0))/NodeTotal;
        density.post(i) = sum(sum(Cpost(:,:,i)>0))/NodeTotal;
    end
    
    disp([9 'Average connectome density pre = ',num2str(mean(density.pre)),...
        ' & post = ',num2str(mean(density.post))]);
end

end

