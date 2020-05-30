import numpy as np
def matrix_threshold(mat, num_edge=100):
    '''
    thresholds a matrix to the top and bottom num_edge edges
    '''
    num_edge = np.int(num_edge / 2)
    nRoi = np.shape(mat)[0]
    mat_pos = np.zeros((np.shape(mat)))
    mat_neg = np.zeros((np.shape(mat)))

    # take the upper triangle
    idx = np.triu_indices(nRoi, k=1)
    mat_vec = mat[idx]

    # order it (positive)
    mat_vec = mat[idx]
    cutoff = np.flip(np.argsort(mat_vec))
    mat_vec[cutoff[num_edge::]] = 0
    mat_pos[idx] = mat_vec

    # order it (negative)
    mat_vec = mat[idx]
    cutoff = np.argsort(mat_vec)
    mat_vec[cutoff[num_edge::]] = 0
    mat_neg[idx] = mat_vec

    mat_new = (mat_pos + mat_pos.T) + (mat_neg + mat_neg.T)
    mat_pos = (mat_pos + mat_pos.T)
    mat_neg = (mat_neg + mat_neg.T)
    return mat_new,mat_pos,mat_neg