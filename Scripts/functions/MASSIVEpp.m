function poolobj = MASSIVEpp(varargin)
        %% MASSIVE parpool
        % specfic code for opening parallel objects on the massive server - see
        % website for details.
        % inputs = ON (1 = start, 0 = stop,scratch_dir,poolobj.
        % poolobj not needed when opening.
        ON = varargin{1};
        scratch_dir = varargin{2};
        
        if ON == 1
            pc = parcluster('local');
          %  scratch_dir = strcat(scratch_dir, getenv('SLURM_JOB_ID'));
            mkdir(scratch_dir);
            pc.JobStorageLocation = scratch_dir;
            poolobj = parpool(pc,str2num(getenv('SLURM_NTASKS')));
        elseif ON == 0
            poolobj = varargin{3};
            delete(poolobj);
            rmdir(scratch_dir,'s');
        end
end

