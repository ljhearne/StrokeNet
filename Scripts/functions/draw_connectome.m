function draw_connectome(MAT,COG,res,s,lw,profile,thresh,direction)
%draws a very basic brain plot of nodes/edges
switch nargin
    case 5
        profile = 1;
        thresh = 0;
        direction = 0;
    case 6
        thresh = 0;
        direction = 0;
    case 7
        direction = 0;
end

if thresh > 0
    %threshold matrix
    newMAT = zeros(size(MAT));
    
    if direction == 0 %use abs
        MATthresh = abs(MAT);
        tmp = sort(MATthresh(:),'descend');
        MATthresh = MATthresh >= tmp(thresh);
        newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
        
    elseif direction == 1 % positive weights
        
        MATthresh = MAT;
        tmp = sort(MATthresh(:),'descend');
        MATthresh = MATthresh >= tmp(thresh);
        newMAT(find(MATthresh>0)) = MAT(MATthresh>0);
        
        newMATneg = zeros(size(MAT));
        MATthresh = MAT;
        tmp = sort(MATthresh(:),'ascend');
        MATthresh = MATthresh <= tmp(thresh);
        newMATneg(find(MATthresh>0)) = MAT(MATthresh>0);
        newMAT = newMAT+newMATneg;
    end
    
    MAT = newMAT;
end

%check MAT is symmetric
MAT2 = zeros(size(MAT));
MAT2 = triu(MAT,1);
MAT2 = MAT2+MAT2';
deg = abs(sum(MAT2)/2);

c = 0;
% list every edge in MNI space.
for i = 1:length(MAT2)
    for j = 1:length(MAT2)
        if MAT2(i,j) ~= 0
            c=c+1;
            edge_x(c,:) = [COG(i,1),COG(j,1)];
            edge_y(c,:) = [COG(i,2),COG(j,2)];
            edge_z(c,:) = [COG(i,3),COG(j,3)];
            strength(c) = MAT2(i,j);
            
        end
    end
end

%draw edges
cmap = parula(res);
[~,bins] = histcounts(strength,res);
bins(2,1:res-1) = bins(1,2:res);

for i = 1:res
    % find edges within the resolution bin
    gre = strength > bins(1,i);
    les = strength <= bins(2,i);
    idx =  gre+les==2;
    
    edge_width = i/res*10*lw;
    alpha = i/res;
    alpha = 0.4;
    if profile == 1
        patchline(edge_x(idx,:),edge_y(idx,:),'edgecolor',cmap(i,:),'linewidth',edge_width,'edgealpha',alpha); hold on
    elseif profile ==2
        patchline(edge_y(idx,:),edge_z(idx,:),'edgecolor',cmap(i,:),'linewidth',edge_width,'edgealpha',alpha); hold on
    elseif profile ==3
        patchline(edge_x(idx,:),edge_z(idx,:),'edgecolor',cmap(i,:),'linewidth',edge_width,'edgealpha',alpha); hold on
    end
end

% draw nodes
if profile == 1
    scatter(COG(:,1),COG(:,2),[],'k','SizeData',(deg/max(deg)*s)+1,'MarkerFaceColor','k'); hold on
elseif profile == 2
    scatter(COG(:,2),COG(:,3),[],'k','SizeData',(deg/max(deg)*s)+1,'MarkerFaceColor','k'); hold on
elseif profile == 3
    scatter(COG(:,1),COG(:,3),[],'k','SizeData',(deg/max(deg)*s)+1,'MarkerFaceColor','k'); hold on
end
end

