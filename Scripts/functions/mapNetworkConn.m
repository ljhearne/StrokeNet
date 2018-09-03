function mapping = mapNetworkConn(MAT,net)
%Simple function that maps from an index of networks and sums the number of
%edges

    MAT = triu(MAT,1);
    tmp = MAT+MAT'; %symmetrize
    
    for i = 1:max(net)
        for j = 1:max(net)
            idxR = net==i;
            idxC = net==j;
            mapping(i,j) = sum(sum(tmp(idxR,idxC)));
        end
    end
end

