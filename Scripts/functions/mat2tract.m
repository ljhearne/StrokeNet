function tract = mat2tract(fibers,streamIDX,chunkSize,tempDir,outfile)
% this function takes our newly defined fibers and converts them
    % to MRTrix format. To avoid using large amounts of memory (due to
    % storing in cells), it does this in two steps. In the first, it splits
    % the connectome into "chunks" and saves each tract seperately in a
    % cell format that is congruent with how the MRTrix-matlab functions
    % want the data. In the second step each of these files are read back
    % into memory and converted into tck format. The left over files are
    % then deleted.
    
    %inputs

    chunkCell = splitvect(streamIDX,chunkSize);
    
    h = waitbar(0,'Please wait: writing cells...');
    
    for chunk = 1:chunkSize
        
        streamIDX_current = [];
        idx = [];
        fibers_current = [];
        
        streamIDX_current = chunkCell{chunk};
        idx = ismember(fibers(:,4),streamIDX_current);
        fibers_current = fibers(idx,:);
        
        parfor i = 1:length(streamIDX_current)% loop and save fibers to cell matrix
            idx = fibers_current(:,4)==streamIDX_current(i);
            allfibcs = fibers_current(idx,1:3);
            data{i} = allfibcs;
        end
        
        % save cells as matlab data (to be read later).
        save([tempDir,outfile,'_chunk',num2str(chunk),...
            '.mat'],'data');
        waitbar(chunk/chunkSize,h);
    end
    close(h)  
    
    % MRTRIX processing
    tract.datatype = 'Float32LE';
    tract.data = cell(1,length(streamIDX));
    
    h = waitbar(0,'Please wait: joining cells...');
    c=1;
    for chunk = 1:chunkSize
        file = [tempDir,outfile,'_chunk',num2str(chunk),...
            '.mat'];
        tmp = load(file);
        
        s = c;
        c = c+length(tmp.data);
        tract.data(s:c-1) = tmp.data;
        
        waitbar(chunk/chunkSize,h);
    end
    close(h)
    system(['rm ',tempDir,'*']);
end

