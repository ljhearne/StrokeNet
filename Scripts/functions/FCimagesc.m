function plotdata = FCimagesc(MAT,net)
%FC matrix imagesc


[newnet,netidx] = sort(net,'ascend');
printMAT = MAT(netidx,netidx);

% summarize functional networks (using mean here).
for net1 = 1:max(newnet)
    
    idx1 = newnet==net1;
    
    for net2 = 1:max(newnet)
        idx2 = newnet==net2;
        tmp = printMAT(idx1,idx2);
        printMAT2(idx1,idx2) = mean(tmp(:));
    end
end

% replace bottom diagonal with network level representation
IDX = ones(size(printMAT));
IDX = tril(IDX);
printMAT(logical(IDX)) = printMAT2(logical(IDX));

plotdata = printMAT;
end

