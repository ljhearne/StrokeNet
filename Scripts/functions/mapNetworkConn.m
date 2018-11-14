function mapping = mapNetworkConn(MAT,net)
%Simple function that maps from an index of networks and sums the number of
%edges

    MAT = triu(MAT,1);
    MAT = MAT+MAT'; %symmetrize
    
    for i = 1:max(net)
        for j = 1:max(net)
            idxR = net==i;
            idxC = net==j;
            
            % by summing
            %mapping(i,j) = sum(sum(MAT(idxR,idxC)));
            
            %by meaning (accounts for number of regions)
            tmp = MAT(idxR,idxC);
            mapping(i,j) = mean(tmp(:));
        end
    end
end

