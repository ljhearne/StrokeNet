function stemplot(CCA,i)
%project specific stemplot for CCA results. Not useful outside this
%analysis as I have been lazy and the function expects very specific file
%structure, inputs = CCA (CCA results) and i (which contrast)
%scatterplot null data
for j = 1:size(CCA.conload,1)
    y = (rand(length(CCA.conloadNull),1) - 0.5)*.25; %jitter
    dataplot = squeeze(CCA.conloadNull(j,i,:));
    scatter(dataplot,y+j,...
        'MarkerEdgeColor',[0.6,0.6,0.6],...
        'MarkerFaceAlpha',0.01,...
        'MarkerEdgeAlpha',0.01,...
        'MarkerFaceColor',[0.6,0.6,0.6]); hold on
end

% stem & scatterplot real data
% draw lines
for j = 1:size(CCA.conload,1)
    dataplot = CCA.conload(j,i);
    if dataplot < 0
        line([dataplot,0],[j,j],'Color','k'); hold on
    else
        line([0,dataplot],[j,j],'Color','k'); hold on
    end
end
% draw circles
scatter(CCA.conload(:,i),1:size(CCA.conload,1),...
    'MarkerEdgeColor','k',...
    'MarkerFaceAlpha',1,...
    'MarkerFaceAlpha',1,...
    'MarkerFaceColor','k'); hold on

end

