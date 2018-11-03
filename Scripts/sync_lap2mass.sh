#!/bin/bash
#rync between server and local
#direction=1 = local to server
#direction=2 = server to local

direction=$1
project='StrokeNet/'
localDir='/Users/luke/Documents/Projects/'${project}'docs/scripts/normativeConnectomes/'
serverDir='lukehearne@m3-dtn.massive.org.au:/projects/sw49/Project_scripts/normativeConnectomes/'

if [ ${direction} == 1 ]
then
  rsync -trvpz ${localDir}* ${serverDir}
elif [ ${direction} == 2 ]
then
  rsync -trvpz ${serverDir}* ${localDir}
fi
