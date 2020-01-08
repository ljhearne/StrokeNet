import numpy as np
from sklearn.cross_decomposition import CCA
from sklearn.utils import shuffle
from tqdm import tqdm

def do_cca(X,y,X_orig,n_components=10,permutations=10):
    '''
    Performs a CCA using components
    Projects scores back to edge space
    '''
    cca = CCA(n_components=n_components)
    cca.fit(X,y)
    
    # save the latent component correlation
    cca.mode_r = []
    for component in range(n_components):
        cca.mode_r.append(np.corrcoef(cca.x_scores_[:,component],cca.y_scores_[:,component])[0,1])

    # correlate behaviour with LC score
    cca.y_score_correlation = np.zeros((np.shape(y)[1],n_components))
    for component in range(n_components):
        for beh in range(np.shape(y)[1]):
            cca.y_score_correlation[beh,component] = np.corrcoef(y[:,beh].T,cca.y_scores_[:,component])[0,1]
    
    # correlate edges with LC score
    cca.x_score_correlation = np.zeros((np.shape(X_orig)[1],n_components))
    for component in range(n_components):
        cca.x_score_correlation[:,component] = np.corrcoef(cca.x_scores_[:,component],X_orig.T)[1::,0]
                
    # non parametric max T tests for component significance
    max_r = []
    for perm in tqdm(range(permutations)):
        #shuffle the behaviour for each permutation
        y_shuffle = shuffle(y)
        
        #perform a new CCA with shuffled data
        cca_perm = []
        cca_perm = CCA(n_components=n_components)
        cca_perm.fit(X,y_shuffle)
        
        # save the latent component correlation
        mode_r_perm = []
        for component in range(n_components):
            mode_r_perm.append(np.corrcoef(cca_perm.x_scores_[:,component],cca_perm.y_scores_[:,component])[0,1])
        
        # take the max r value
        max_r.append(np.max(mode_r_perm))

    # Compute adjusted p-values via percentile
    p_adj = []
    for component in range(n_components):
        p_adj.append(np.mean(max_r >= cca.mode_r[component]))

    return cca,p_adj