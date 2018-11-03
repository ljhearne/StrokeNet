function [fibers,conboundResult, subIDX] = gen_NormConnectome(data,age,sex,conbound)
%gen_NormConnectome(data,age,gender,conbound)
%   Takes a set of normative connectomes from LEADDBS and selects specific
%   age and gender related connections

streamIDX = unique(data.fibers(:,4)); %index of connectomes

% SEX
idx = data.sex==sex;
data.age = data.age(idx);
data.sub = data.sub(idx);
streamIDX = streamIDX(idx);

% AGE
% age is selected by the conbound closest connectomes
[idxsub,idx] = unique(data.sub);
ageidx = data.age(idx);

[tmp,idx] = sort(abs(ageidx - age),'ascend');
idx = idxsub(idx(1:conbound));
idx2 = ismember(data.sub,idx);

conboundResult = tmp(conbound);
    
streamIDX = streamIDX(idx2);
subIDX = unique(data.sub(idx2));

disp(['... including ',num2str(length(subIDX)),' unique connectomes']);

% remove fibers that are not needed
idx = ismember(data.fibers(:,4),streamIDX);
fibers = data.fibers(idx,:);
end

