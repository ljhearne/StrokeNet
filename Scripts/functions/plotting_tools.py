from nilearn import plotting
import matplotlib.pyplot as plt
from matplotlib import cm as colmap
import numpy as np
import nibabel as nib
import seaborn as sns
from scipy.stats import spearmanr
from .matrix_threshold import *
from .remove_border import *
from numpy.polynomial.polynomial import polyfit
from scipy.stats import gaussian_kde

'''
These are a collection of custom functions to plot figures in the stroke project

'''
plt.style.use('seaborn-white')
affine = np.array([[  -1.,    0.,    0.,   90.],
       [   0.,    1.,    0., -126.],
       [   0.,    0.,    1.,  -72.],
       [   0.,    0.,    0.,    1.]])

def lesion_dist_nii(NIFTI,title=None,slices=np.arange(-28, 62, 12)):
    array_data = np.sum(NIFTI,axis=3)
    img = nib.Nifti1Image(array_data, affine)
    plotting.plot_stat_map(img,
                           threshold=0.99,
                           colorbar=True,
                           cmap='viridis',
                           display_mode='z',
                           cut_coords=(slices))
    if title is not None:
        plt.savefig(title,dpi=600)
    plt.show()
    
def lesion_dist_cm(cm,MNIcoords,title=None,vmin=-30,vmax=30):
    #binarize
    cm[cm > 0] = 1
    cm = np.sum(cm, axis=2)
    
    #symmetrize
    cm = cm + cm.T
    cm_degree = np.sum(abs(cm), axis=1)
    cm_degree_plot = (cm_degree / np.max(cm_degree)) * 100
    plotting.plot_connectome(cm,
                             MNIcoords,
                             node_size=cm_degree_plot,
                             node_color='black',
                             edge_cmap='viridis',
                             edge_vmin=vmin, # to get same colour echeme as the nifti plot set to opposite
                             edge_vmax=vmax,
                             colorbar=True,
                             display_mode='lzr',
                             edge_kwargs={'Alpha':0.25,'lw':1},
                             node_kwargs={'Alpha':0,'lw':0})
    if title is not None:
        plt.savefig(title,dpi=600)
    plotting.show()
    
def behav_heatmap(data,labels,title=None):
    # rank correlation between behavioural variables
    corr = spearmanr(data)[0]
    print(corr)
    mask = np.zeros_like(corr)
    mask[np.triu_indices_from(mask)] = True
    plt.figure(figsize=(3.2, 2.4))
    sns.heatmap(corr,
                vmin=-0,
                vmax=0.5,
                cmap='viridis',
                center=0,
                annot=True,
                fmt='.1f',
                mask=mask,
                linewidths=1,
                xticklabels=labels[0:4],
                yticklabels=labels)
    if title is not None:
        plt.savefig(title,dpi=600)
    plt.show()
    
def MCA_cm_plots(mca,MCA_components,MNIcoords,num_edge=200,title=None):
    vmin = -4
    vmax = 4
    fh = plt.figure(figsize=(10,5))
    
    for component in range(MCA_components):
        ax = fh.add_subplot(1, MCA_components, component+1)
        cm = mca.edge_scores_mat[:,:,component]
        cm = cm + cm.T
        cm = matrix_threshold(cm, num_edge=num_edge)
        plotting.plot_connectome(cm,
                                 MNIcoords,
                                 axes=ax,
                                 node_size=0,
                                 edge_cmap='vlag',
                                 annotate = False,
                                 edge_vmin=vmin,
                                 edge_vmax=vmax,
                                 colorbar=False,
                                 display_mode='z',
                                 edge_kwargs={'Alpha':0.75,'lw':1})
        plt.title(np.round(mca.eigenvalues_[component],2))
    if title is not None:
        plt.savefig('MCA_edgeweights_'+title,dpi=600)
    plotting.show()

    # plot the colorbar
    fh = plt.figure(figsize=(2.5,2.5))
    ax = fh.add_subplot(1,1,1)
    plotting.plot_connectome(cm,
                             MNIcoords,
                             axes=ax,
                             node_size=0,
                             edge_cmap='vlag',
                             annotate = False,
                             edge_vmin=vmin,
                             edge_vmax=vmax,
                             colorbar=True,
                             display_mode='z',
                             edge_kwargs={'Alpha':0.75,'lw':1})
    if title is not None:
        plt.savefig('MCA_colorbar_'+title,dpi=600)
    plotting.show()

    # plot the individual MCA weights
    plt.figure(figsize=(2.5, 2.5))
    plt.imshow(mca.ind_scores[:,0:MCA_components],cmap='vlag',vmin=-1,vmax=1,aspect="auto")
    plt.xticks(range(MCA_components),np.arange(1,MCA_components+1))
    plt.xlabel('Components')
    plt.ylabel('Participants')
    if title is not None:
        plt.savefig('MCA_indweights_'+title,dpi=600)
    plt.show()
    
def CCA_UV_plot(cca,mode=0,title=None):
    #get x and y
    x = cca.x_scores_[:,mode].copy()
    y = cca.y_scores_[:,mode].copy()

    # Fit trend line with polyfit
    b, m = polyfit(x,y, 1)

    # Calculate the point density for alpha values
    xy = np.vstack([x, y])
    z = gaussian_kde(xy)(xy)
    z = (1 - z * 2) - .2

    plt.figure(figsize=(2, 2))
    colors = sns.cm.vlag(x)
    for i in range(len(z)):
        #colors[i, :] = [0.5,0.5,0.5,0]
        colors[i, 3] = np.float(z[i])/2
    plt.scatter(x, y, s=20, linewidth=0, color=colors)

    colors = sns.cm.vlag(y)
    for i in range(len(z)):
        #colors[i, :] = [0.5,0.5,0.5,0]
        colors[i, 3] = np.float(z[i])/2
    plt.scatter(x, y, s=20, linewidth=0, color=colors)
    plt.plot(x, b + m * x, '-', linewidth=1, color='k')

    #params
    #plt.xlim(-2.8, 2.8)
    #plt.ylim(-2.8, 2.8)
    plt.xlabel("Connectivity weights (arb. unit)")
    plt.ylabel("Behaviour weights (arb. unit)")
    remove_border()
    if title is not None:
        plt.savefig(title,dpi=600)
    plt.show()
    
def CCA_behav_plot(cca,labels,mode=0,title=None):
    # get correlated behavioural loadings
    x = cca.y_score_correlation[:,mode].copy()
    y_pos = np.arange(len(x))
    colors = sns.cm.vlag((x + 1) / 2)

    plt.figure(figsize=(1,2))
    plt.barh(y_pos, x, align='center', color=colors, ecolor=colors)
    plt.xlim(-1, 1)
    plt.yticks(range(len(labels)), labels)
    plt.xlabel("Correlation between behaviour and CCA mode (r)")
    remove_border(left=None)
    if title is not None:
        plt.savefig(title,dpi=600)
    plt.show()

def CCA_cm_brain_plot(cca,MNIcoords,mode=0,num_edge=200,title=None):
    cm = cca.x_weights_mat[:,:,mode]
    cm = cm + cm.T
    cm_degree = np.sum(abs(cm), axis=1)
    cm = matrix_threshold(cm, num_edge=num_edge)
    cm_degree_plot = (cm_degree / np.max(cm_degree)) * 75
    plotting.plot_connectome(cm,
                             MNIcoords,
                             node_size=cm_degree_plot,
                             node_color='black',
                             edge_cmap='vlag',
                             edge_vmin=-1,
                             edge_vmax=1,
                             display_mode='lzr',
                             edge_kwargs={'Alpha':0.75,'lw':1},
                             node_kwargs={'Alpha':0,'lw':0},
                             colorbar=True)
    if title is not None:
        plt.savefig(title,dpi=600)
    plotting.show()
    
def CCA_nifti_brain_plot(cca,mode=0,title=None):
    array_data = cca.x_weights_mat[:,:,:,mode]
    img = nib.Nifti1Image(array_data, affine)
    plotting.plot_stat_map(img,cmap='viridis',vmax=1,display_mode='z',colorbar=True)
    if title is not None:
        plt.savefig(title,dpi=600)
    plotting.show()
    
def network_plot(network_mean,network_labels,mode=0,title=None):
    vmin=0.15
    vmax=0.45
    
    for direction in ['pos','neg']:
        data = network_mean[direction][:,:,mode]
        mask = np.zeros_like(data)
        mask[np.triu_indices_from(mask,k=1)] = True
        plt.figure(figsize=(2.5,2))
        sns.heatmap(abs(data),
                    vmin=vmin,
                    vmax=vmax,
                    cmap='viridis',
                    annot=False,
                    fmt='.2f',
                    mask=mask,
                    linewidths=1,
                    xticklabels=network_labels,
                    yticklabels=network_labels)
        plt.title(direction)
        if title is not None:
            plt.savefig(title,dpi=600)
        plt.show()