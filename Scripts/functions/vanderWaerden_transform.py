#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Dec  9 21:58:12 2019

@author: luke
"""
from scipy.stats import norm
import numpy as np
def vanderWaerden_transform(data):
    '''
    From Smith et al., HCP CCA paper.
    We used a rank-based inverse Gaussian transformation29, to enforce
    Gaussianity for each of the SMs, producing S2. This transformation was
    used to avoid undue influence of potential outlier values, although we
    later confirmed that this normalisation made almost no difference to the
    final CCA results (see below).

    Also see https://brainder.org/tag/rank-based-inverse-normal-transformation/
    '''
    new_data = np.zeros(np.shape(data))
    n_vars = np.shape(data)[1]
    for var in range(n_vars):
        temp = data[:,var]
        
        order = temp.argsort()
        rank = order.argsort()
        rank = rank+1 # + 1 for pythonic indexing
        
        p = rank / (len(rank) + 1) # +1 to avoid Inf for the max point
        q = norm.ppf(p) 
        new_data[:,var] = q
    return new_data