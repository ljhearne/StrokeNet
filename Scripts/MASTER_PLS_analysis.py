#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Dec  8 14:51:26 2019

@author: luke
"""
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from StrokeNet_functions import load_data
from sklearn.utils import shuffle
from scipy.stats import zscore
from sklearn.cross_decomposition import PLSRegression
from scipy.stats import spearmanr

# inputs
parcellation = 'Sch240'
n_connectomes = '20'
behaviour_list = ['APM','NART_IQ','Q1_TotalWords','Q6_TotalCorrect','CoC_abs_rev','GreyScale%Rev']
normalise_behav = True
PLSpermutations = 1000
n_components = 10
#dir_data = '/Users/luke/Documents/Projects/StrokeNet/Data/'
#dir_docs = '/Users/luke/Documents/Projects/StrokeNet/Docs/'


behav_df, CM = load_data(parcellation=parcellation,
                         n_connectomes=n_connectomes,
                         behaviour_list=behaviour_list)


## Print demographic information (you can do this last)

## Organise PLS

# reshape connectivity data
n_subs = np.shape(CM['Diff'])[2]
n_nodes = np.shape(CM['Diff'])[0]
n_edges = np.int((n_nodes*(n_nodes-1))/2)

X_full = np.zeros((n_subs,n_edges))
index_upper = np.triu_indices(n_nodes, k=1)
for subj in range(n_subs):
    data = CM['Diff'][:,:,subj].copy()
    X_full[subj,:] = data[index_upper]
#X_full = X_full>0

# remove non informative features
keep_features = np.sum(X_full,axis=0)>0
X = X_full[:,keep_features]
y = behav_df[behaviour_list].values
if normalise_behav:
    y = zscore(y,axis=0)

# do pls
pls = []
pls = PLSRegression(n_components=n_components)
pls.fit(X,y)
x_r, y_r = pls.transform(X, y, copy=True)
LC_r = []
for component in range(n_components):
    LC_r.append(np.corrcoef(pls.x_scores_[:,component],pls.y_scores_[:,component])[0,1])
    #LC_r.append(spearmanr(pls.x_scores_[:,component],pls.y_scores_[:,component])[0])

print(LC_r)
    #LC_r.append(spearmanr(pls.x_scores_[:,component],pls.y_scores_[:,component])[0])

# non parametric max T tests for component significance
max_r = []
for perm in range(PLSpermutations):
    y_shuffle = shuffle(y)

    pls_perm = PLSRegression(n_components=n_components,max_iter=1000)
    pls_perm.fit(X,y_shuffle)

    LC_r_perm = []
    for component in range(n_components):
        LC_r_perm.append(np.corrcoef(pls_perm.x_scores_[:,component],pls_perm.y_scores_[:,component])[0,1])

    max_r.append(np.max(LC_r_perm))

# Compute adjusted p-values
p_adj = []
for component in range(n_components):
    p_adj.append(np.mean(max_r >= LC_r[component]))

print(p_adj)

# put weights back in original space
pls.x_weights_mat = np.zeros((n_nodes,n_nodes,2))
for i in range(2):
    data = np.zeros((len(keep_features)))
    data[keep_features] = pls.x_weights_[:,i]
    data_mat = np.zeros((n_nodes,n_nodes))
    data_mat[index_upper] = data
    pls.x_weights_mat[:,:,i] = data_mat
    plt.imshow(pls.x_weights_mat[:,:,i],aspect='auto')
    plt.show()
#     cv = KFold(n_splits=5,shuffle=True)
#     y_pred = np.zeros((np.shape(y)))
#     #y_test = []

#     for train_index, test_index in cv.split(X):
#         #organise the data into training and testing sets
#         X_train = X[train_index,:]
#         y_train = y[train_index,:]
#         X_test  = X[test_index,:]

#         # nested validation to define number of components
#         best_comp = nested_components_PLS(X_train,y_train)
#         print(best_comp)
# #         # define PLS object
# #         pls = PLSRegression(n_components=n_comps,max_iter=1000)

# #         # fit pls object
# #         pls.fit(X_train, y_train)

# #         # predict left out values
# #         y_pred[test_index,:] = pls.predict(X_test)

# #     # save predictions for this iteration
# #     for i in range(np.shape(y)[1]):
# #         r[perm,i] = spearmanr(y[:,i],y_pred[:,i])[0]
# #         MAE[perm,i] = mean_absolute_error(y[:,i],y_pred[:,i])
# #         Rsqr[perm,i] = r2_score(y[:,i],y_pred[:,i])
# #     x_r.append(np.corrcoef(pls.x_scores_[:,0],pls.y_scores_[:,0])[0,1])
# #     x_r_mean.append(np.mean(x_r))


# # # put weights back in original space
# # n_comps = 2
# # pls.x_weights_mat = np.zeros((n_nodes,n_nodes,n_comps))
# # for i in range(n_comps):
# #     data = np.zeros((len(keep_features)))
# #     data[keep_features] = pls.x_weights_[:,i]
# #     data_mat = np.zeros((n_nodes,n_nodes))
# #     data_mat[index_upper] = data
# #     pls.x_weights_mat[:,:,i] = data_mat

# #print(np.mean(r,axis=0))
# #print(np.mean(MAE,axis=0))
# #print(np.mean(Rsqr,axis=0))
# #print(np.mean(np.mean(Rsqr,axis=0)))
# #print(np.mean(x_r))

# #u = ((y[:,0] - y_pred[:,0]) ** 2).sum()
# #v = ((y[:,0] - y[:,0].mean()) ** 2).sum()

# #print(u,v)

# #plt.imshow(y,aspect='auto')
# #plt.colorbar()
# #plt.show()
#     #MAE.append(mean_absolute_error(np.concatenate(y_test, axis=0), np.concatenate(y_pred, axis=0)))
#     #Rsqr.append(r2_score(np.concatenate(y_test, axis=0), np.concatenate(y_pred, axis=0)))
# ## Define PLS object
# #pls = PLSRegression(n_components=1)
# #
# ## predictors
# #X = task_betas.copy().T
# ## response
# #Y = beh_data.copy().T
# ## Fit pls object
# #pls.fit(X, Y)
# #
# ## correlate with original values to derive descriptive weights
# #pls.x_LC_corr = []
# #for i in range(np.shape(X)[1]):
# #    pls.x_LC_corr.append(np.corrcoef(pls.x_scores_[:,0],X[:,i])[0,1]) #weights or loadings?
# #pls.x_LC_corr = np.asarray(pls.x_LC_corr)
# #
# #pls.y_LC_corr = []
# #for i in range(np.shape(Y)[1]):
# #    pls.y_LC_corr.append(np.corrcoef(pls.y_scores_[:,0],Y[:,i])[0,1]) #weights or loadings?
# #pls.y_LC_corr = np.asarray(pls.y_LC_corr)
# ## Network description analysis

# ## Do the same analysis in voxel space!

# ## Cross validated PLS

# ## Compare the two methods