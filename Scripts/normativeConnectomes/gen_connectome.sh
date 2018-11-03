#!/bin/bash

export LD_LIBRARY_PATH=''

module load mrtrix/0.3.16

IN=$1
OUT=$3
PARC=$2
OA=$4

tck2connectome $IN $PARC $OUT -assignment_radial_search 2 -zero_diagonal -out_assignments $OA -force
