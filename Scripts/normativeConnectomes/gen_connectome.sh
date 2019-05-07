#!/bin/bash

export LD_LIBRARY_PATH=''

module load mrtrix/0.3.16

IN=$1
OUT=$3
PARC=$2
OA=$4

tck2connectome $IN $PARC ${OUT}.csv -assignment_radial_search 2 -zero_diagonal -quiet -nthreads 12 -force
tck2connectome $IN $PARC ${OUT}_invlengthweights.csv -assignment_radial_search 2 -zero_diagonal -quiet -nthreads 12 -scale_invlength -force
tck2connectome $IN $PARC ${OUT}_invnodelengthweights.csv -assignment_radial_search 2 -zero_diagonal -quiet -nthreads 12 -scale_invlength -scale_invnodevol -force