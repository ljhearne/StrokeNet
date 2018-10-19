#!/bin/bash

#freesurfer_vis.sh
datadir='/Users/luke/Documents/Projects/StrokeNet/Data/'
docsdir='/Users/luke/Documents/Projects/StrokeNet/Docs/'
lesiondir=${datadir}lesionMaps/3_rNii/
T1Atlas=${docsdir}Atlas/MNI152_T1_1mm.nii
echo ${T1Atlas}

# create lists for data
lesionlist=(${lesiondir}*)

#loop
for lesion in "${lesionlist[@]}"; do
   echo ${lesion}
done


#subj='rP001_GB.nii'
#lesion=
#echo ${lesion}
#freeview --volume ${T1Atlas} \
#${lesion}
