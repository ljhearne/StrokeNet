function draw_connectome(MAT,COG,res,s,lw)
%draws a very basic brain plot of nodes/edges


%check MAT is symmetric
MAT2 = zeros(size(MAT));
MAT2 = triu(MAT,1);
MAT2 = MAT2+MAT2';
deg = abs(sum(MAT2)/2);

c = 1;
% list every edge in MNI space.
for i = 1:length(MAT2)
    for j = 1:length(MAT2)
        edge_x(c,:) = [COG(i,1),COG(j,1)];
        edge_y(c,:) = [COG(i,2),COG(j,2)];
        edge_z(c,:) = [COG(i,3),COG(j,3)];
        strength(c) = MAT2(i,j);
        c=c+1;
    end
end

%draw edges
cmap = [parula(res)];
[count,bins] = histcounts(strength,res);
bins(2,1:res-1) = bins(1,2:res);
for i = 1:res
    % find edges within the resolution bin
    gre = strength > bins(1,i);
    les = strength <= bins(2,i);
    idx =  gre+les==2;
    
    edge_width = i/res*10*lw;
    alpha = i/res;
    alpha = 0.4;
    patchline(edge_x(idx,:),edge_y(idx,:),'edgecolor',cmap(i,:),'linewidth',edge_width,'edgealpha',alpha); hold on
end

% draw nodes
scatter(COG(:,1),COG(:,2),[],'k','SizeData',(deg/max(deg)*s)+1,'MarkerFaceColor','k'); hold on

end

