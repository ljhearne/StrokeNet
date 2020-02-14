import numpy as np
from sklearn.utils import shuffle

def net_affilation_cm(cca_weights,CCA_components,networks,edge_limit=30):
    
    #edge_limit = 30 # the number of edges needed to constitute an average
    n_networks = np.max(networks)
    #network_mean = {}
    #network_mean['pos'] = np.zeros((n_networks,n_networks,CCA_components))
    #network_mean['neg'] = np.zeros((n_networks,n_networks,CCA_components))
    network_mean = np.zeros((n_networks,n_networks,CCA_components))

    for mode in range(CCA_components):
        data = cca_weights[:,:,mode] + cca_weights[:,:,mode].T

        for i in np.unique(networks):
            index_i = np.ravel(networks==i)

            for j in np.unique(networks):
                index_j = np.ravel(networks==j)

                edge_data = []
                edge_data = data[index_i,:]
                edge_data = edge_data[:,index_j]

                # remove zeros that have not loaded on (i.e., excluded connections)
                edge_data = edge_data[edge_data!=0]
                
                # use absolute values so that positive and negative edges do not cancel out
                edge_data = abs(edge_data)
                if len(edge_data) < edge_limit:
                    network_mean[i-1,j-1,mode] = 0
                else:
                    # calculate average loadings
                    network_mean[i-1,j-1,mode] = np.nanmean(edge_data[edge_data>0])
    return network_mean

def net_affilation_wrapper(cca_weights,CCA_components,networks,permutations=1000):

    # preallocate
    cca_weights_shuffled = np.zeros((cca_weights.shape))

    # generate actual results
    network_mean = net_affilation_cm(cca_weights,CCA_components,networks)

    max_mean = np.zeros((permutations))
    for perms in range(permutations):
        
        # generate shuffled matrices
        for mode in range(CCA_components):
            data = cca_weights[:,:,mode].copy()
            index = np.triu_indices(data.shape[0],k=1)

            #shuffle the data
            data_shuffled = shuffle(data[index])
            tmp = np.zeros((data.shape))
            tmp[index] = data_shuffled
            cca_weights_shuffled[:,:,mode] = tmp

        # calculate network means in shuffled data
        net_mean_perm = net_affilation_cm(cca_weights_shuffled,CCA_components,networks)

        # take the max value across all modes
        max_mean[perms] = np.max(abs(net_mean_perm))

    # compare real and null values
    # Compute adjusted p-values via percentile
    p_fwe = np.zeros((network_mean.shape))
    for mode in range(CCA_components):
        for i in range(np.max(networks)):
            for j in range(np.max(networks)):
                data = network_mean[i,j,mode]
                p_fwe[i,j,mode] = np.mean(max_mean >= data)
    return network_mean, p_fwe