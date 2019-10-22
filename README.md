# StrokeNet Project
This directory contains code for the stroke lesion network mapping project.

##
The primary analysis for this project is a leave-one-out prediction of multiple behaviours using canonical correlation analysis

## Lesion network mapping
If you are interested in using the matlab code to do lesion network mapping with LEAD DBS see scripts/NormativeConnectomes for the matlab code. While the code is commented and relatively readable I have no future plans to release this code in a more 'official' capacity, but I'm happy to answer questions. Most of the hard work is all within the LEAD DBS package and credit goes to Andreas Horn.

## Instructions for coauthors
Folders should be organized like so:
```
project folder 
│
└───Data (not available online)
│   └───BehaviouralDatabase....xlsx
│   └───connectomes
│   │   └───conboundX (X references the age-limit of the normative connectomes)
│   │   │   └───parcellation (e.g., Schaefer + HO 214)
│   └───lesionMaps
│   │   └───1_Raw (original lesion maps)
│   │   └───2_Nii (converted)
│   │   └───3_rNii (coregistered to MNI space)
│   └───tracts
│       └───conboundX 
└───Docs (this repository)
    │    ...
    └─── Scripts
```
