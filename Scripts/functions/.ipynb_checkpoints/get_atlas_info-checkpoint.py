from scipy.io import loadmat

def get_atlas_info(parcellation='Sch240'):
    if parcellation == 'Sch240':
        file = '/Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/Schaefer200/240COG.mat'
    MNIcoords = loadmat(file)['COG']


    if parcellation == 'Sch240':
        file = '/Users/luke/Documents/Projects/StrokeNet/Docs/Atlas/Schaefer200/240parcellation_Yeo8Index.mat'
    networks = loadmat(file)['Yeo8Index']
    network_labels = ['Vis', 'SomMat', 'DorstAttn', 'SalVentAttn', 'Limbic', 'Control', 'Default', 'SC','Cerebellum']
    
    return MNIcoords, networks, network_labels