import numpy as np
import seaborn as sns
from nilearn import plotting
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
from .matrix_threshold import *

def plot_connectome_threshold(cm,MNIcoords,num_edge=250,display_mode='lzr',edge_alpha=0.75,edge_lw=1,title='test'):
    '''
    Plots the top/bottom 'num_edges' in a nilearn connectome plot
    as opposed to a percentage of the edges.
    Colors the positive and negative edges seperately using vlag
    
    '''
    # create positive colormap
    new_cmap = sns.cm.vlag(np.arange(0.55,1,.001),alpha=None)
    new_cmap = ListedColormap(new_cmap)
    
    # get positive / negative data
    cm,cm_pos,cm_neg = matrix_threshold(cm, num_edge=num_edge)
    
    # get vmin/vmax
    edge_vmin=np.min(cm_pos[cm_pos>0])
    edge_vmax=np.max(cm_pos)
    
    # plot first connectome
    connectome = plotting.plot_connectome(cm_pos,MNIcoords,
                         node_size=0,
                         node_color='black',
                         edge_cmap=new_cmap,
                         edge_vmin=edge_vmin,
                         edge_vmax=edge_vmax,
                         display_mode=display_mode,
                         edge_kwargs={'Alpha':edge_alpha,'lw':edge_lw},
                         node_kwargs={'Alpha':0,'lw':0},
                         alpha=0.1,
                         annotate=False,
                         colorbar=True)
    # saves the colorbar out
    plt.savefig(title+'1.svg')
    
    # negative plot
    new_cmap = sns.cm.vlag(np.arange(0,0.45,.001),alpha=None)
    new_cmap = ListedColormap(np.flipud(new_cmap))
    
    #adjust cm
    cm_neg = cm_neg*-1
    
    # new vmins
    edge_vmin=np.min(cm_neg[cm_neg>0])
    edge_vmax=np.max(cm_neg)
    
    #add graph
    connectome.add_graph(cm_neg,MNIcoords,
                             node_size=0,
                             node_color='black',
                             edge_cmap=new_cmap,
                             edge_vmin=edge_vmin,
                             edge_vmax=edge_vmax,
                             edge_kwargs={'Alpha':edge_alpha,'lw':edge_lw},
                             node_kwargs={'Alpha':0,'lw':0},
                             colorbar=True)
    plt.savefig(title+'2.svg')
    plotting.show()