function chunkCell = splitvect(v, n)
% % Splits a vector into number of n chunks of  the same size (if possible).
% % In not possible the chunks are almost of equal size.

vectLength = round(length(v)/(n+1)); %ensures it is shorter

count = 1;
for i = 1:n
    if i<n
        begin = count;
        count = count+vectLength;
        chunkCell{i} = v(begin:count-1);
    else
        begin = count;
        chunkCell{i} = v(begin:end); % the last cell will always be larger
    end
end