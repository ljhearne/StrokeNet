#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec  9 21:58:12 2019

@author: luke
"""

import numpy as np
import pandas as pd
from tqdm import tqdm

def load_data(parcellation='Sch240',
              n_connectomes='20',
              behaviour_list=['APM', 'NART_IQ', 'Q1_TotalWords',
                              'Q6_TotalCorrect', 'CoC_abs_rev']):
    '''
    Function that loads behaviour as a pandas dataframe and loads connectivity
    matrices into a list of numpy arrays - Lesion, NoLesion and Diff.
    Note that it contains two absolute paths that may need to be changed.
    '''

    # load behaviour
    spreadsheet = '/Users/luke/Documents/Projects/StrokeNet/Data/Stroke_Lucy_031219_edit.xlsx'
    df = pd.read_excel(spreadsheet)
    n_subjs = len(df)

    # load connectivity
    dir_connectomes = '/Users/luke/Documents/Projects/StrokeNet/Data/' \
     + 'connectomes/conbound' + n_connectomes+'/' + parcellation + '/'

    if parcellation == 'Sch240':
        n_nodes = 240
    elif parcellation == 'Sch214':
        n_nodes = 214
    elif parcellation == 'BN':
        n_nodes = 246

    CM = {}
    CM['Lesion'] = np.zeros((n_nodes, n_nodes, n_subjs))
    CM['NoLesion'] = CM['Lesion'].copy()
    CM['Diff'] = CM['Lesion'].copy()
    brain_data = np.zeros((n_subjs))

    for i, subj in enumerate(df['ID']):
        for conn_type in ['NoLesion', 'Lesion']:
            file = dir_connectomes + subj + '_' + conn_type + '_SC_invlengthweights.csv'

            try:
                CM[conn_type][:,:,i] = np.loadtxt(file, delimiter=' ')
                brain_data[i] = 1
            except:
                CM[conn_type][:,:,i] = np.nan
                brain_data[i] = 0

        # create pre - post lesion difference data
        CM['Diff'][:,:,i] = CM['NoLesion'][:,:,i] - CM['Lesion'][:,:,i]

    # exclude missing data
    df['brain_data'] = brain_data
    index = df['brain_data'] == 1
    for behav in behaviour_list:
        index = np.vstack((index, ~np.isnan(df[behav].values)))
    index = np.sum(index, axis=0) == len(behaviour_list) + 1

    # trim behaviour
    df.drop(np.where(~index)[0], inplace=True)

    # trim connectivity
    for conn_type in ['Diff', 'Lesion', 'NoLesion']:
        CM[conn_type] = np.delete(CM[conn_type], np.where(~index)[0], axis=2)
    return df, CM