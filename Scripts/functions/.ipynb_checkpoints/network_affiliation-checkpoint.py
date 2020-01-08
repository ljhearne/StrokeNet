import numpy as np

def network_affilation_cm(cca,CCA_components,networks):

    n_networks = np.max(networks)
    network_mean = {}
    network_mean['pos'] = np.zeros((n_networks,n_networks,CCA_components))
    network_mean['neg'] = np.zeros((n_networks,n_networks,CCA_components))

    for mode in range(CCA_components):
        data = cca.x_weights_mat[:,:,mode] + cca.x_weights_mat[:,:,mode].T

        for i in np.unique(networks):
            index_i = np.ravel(networks==i)

            for j in np.unique(networks):
                index_j = np.ravel(networks==j)

                edge_data = []
                edge_data = data[index_i,:]
                edge_data = edge_data[:,index_j]

                # remove zeros that have not loaded on (i.e., excluded connections)
                edge_data = edge_data[edge_data!=0]

                # calculate positive loadings
                network_mean['pos'][i-1,j-1,mode] = np.mean(edge_data[edge_data>0])
                network_mean['neg'][i-1,j-1,mode] = np.mean(edge_data[edge_data<0])
    return network_mean