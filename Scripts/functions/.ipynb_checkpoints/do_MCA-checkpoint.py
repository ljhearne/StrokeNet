from prince import MCA
import warnings
warnings.filterwarnings("ignore", category=FutureWarning) 

def do_MCA(X,n_components=10):
    '''
    Performs multiple correspondance analysis on X
    
    '''
    warnings.filterwarnings("ignore", category=FutureWarning) 
    # run the MCA using prince
    mca = MCA(n_components=n_components)
    mca = mca.fit(X)

    # individual loadings onto components
    mca.ind_scores = mca.row_coordinates(X).values

    # edge loadings onto components
    edge_scores = mca.column_coordinates(X).values

    # exclude every other row (the zero loadings)
    mca.edge_scores = edge_scores[1::2,:]
    
    return mca