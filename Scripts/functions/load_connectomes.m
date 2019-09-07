function [Cpre,Cpost,nodata,Cpresym,Cpostsym] = load_connectomes(path)
% loads the stroke connectomes ~ specific to stroke project, just a simple
% loop 
% outputs all connectomes - even if they don't "exist" - these can be
% trimmed later by use of the "nodata" variable. The second set of
% variables are symmetric matrices.

[~, ~, P_ID] = load_stroke_behav;
sep = ' ';

% get number of nodes.
file = [path,P_ID{1},'_NoLesion_SC','.csv'];
tmp = dlmread(file,sep);
N = size(tmp,1);

Cpre = zeros(N,N,length(P_ID));
Cpost = zeros(size(Cpre));
nodata = zeros(length(P_ID),1);

for i = 1:length(P_ID)
    try
        %_invnodelengthweights
        file = [path,P_ID{i},'_NoLesion_SC_invlengthweights','.csv'];
        Cpre(:,:,i) = dlmread(file,sep);
        
        file = [path,P_ID{i},'_Lesion_SC_invlengthweights','.csv'];
        Cpost(:,:,i) = dlmread(file,sep);
        
        Cpresym(:,:,i) = Cpre(:,:,i)+Cpre(:,:,i)';
        Cpostsym(:,:,i) = Cpost(:,:,i)+Cpost(:,:,i)';
        
        
    catch
        Cpre(:,:,i) = nan;
        Cpost(:,:,i) = nan;
        nodata(i) = 1;
    end
end

end

