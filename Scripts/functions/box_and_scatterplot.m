function box_and_scatterplot(data,place,lw,s,col,alpha)
%combination_plot(data,place,lw,s,col,alpha)
%plots mean and CI on left and then scattered raw data on right.

% these are jitter and width parameters - should keep consistent.
placewidth = 0.05;
a = 0; 
b = 0.2;
newplace = place - placewidth;

% Draw patch
patch([newplace-b, newplace, newplace, newplace-b],...
    [prctile(data,25),prctile(data,25),prctile(data,75),prctile(data,75)],...
    col,'FaceAlpha',alpha);

% Draw horizontal lines
line([newplace-b newplace],[median(data),median(data)],'Color','k','LineWidth',1); hold on
line([newplace-b newplace],[prctile(data,25),prctile(data,25)],'Color','k','LineWidth',1); hold on
line([newplace-b newplace],[prctile(data,75),prctile(data,75)],'Color','k','LineWidth',1); hold on
line([newplace-b/2 newplace],[prctile(data,5),prctile(data,5)],'Color','k','LineWidth',1); hold on
line([newplace-b/2 newplace],[prctile(data,95),prctile(data,95)],'Color','k','LineWidth',1); hold on

% Draw vertical lines
line([newplace newplace],[prctile(data,5),prctile(data,95)],'Color','k','LineWidth',1); hold on
line([newplace-b newplace-b],[prctile(data,25),prctile(data,75)],'Color','k','LineWidth',1); hold on

% draw scatter
r = a + (b-a).*rand(length(data),1);
newplace = place + placewidth;
scatter(r+newplace,data,...
        'MarkerEdgeColor',col,...
        'LineWidth',lw,...
        'MarkerFaceAlpha',alpha,...
        'MarkerEdgeAlpha',alpha,...
        'MarkerFaceColor', col,...
        'SizeData',s); hold on
end

