#!/usr/bin/env bash

set -xe

#########
# 
# get bb244 rois in subject native space
# and get timecouse of the aveage in each ROI
# must have run rest_redoBad and have bp+ort bp+3dD folders
# 
#  switches:
#########

subjdir="/data/Luna1/Reward/Rest/10845_20100924/"
cd $(dirname $0)
bb244=bb244MNI_LPI_2mm.nii.gz

subjexample="/data/Luna1/Reward/Rest/10152_20111123/preproc_torque/rest_preproc_mni.nii.gz"
if [ ! -r $bb244 ]; then
   ### original bb244 might be bad?
   #3dcopy -overwrite bb244+tlrc bb244MNI.nii.gz
   #3dresample -overwrite -inset bb244MNI.nii.gz -prefix bb244MNI_res.nii.gz -master /Volumes/Serena/Rest/Subjects/10153/pipeTests/bp+ort_noPhysio/rest_preproc_mni.nii.gz
  3dUndump -srad 5 -prefix $bb244  -master $subjexample \
           -orient LPI -xyz bb244_coordinate
fi


#find $subjdir -maxdepth 4 -mindepth 4 -name rest_preproc_MNI.nii.gz | while read file; do
#for file in $subjdir/*/pipeTests/*/rest_preproc_mni.nii.gz; do
[ -d ROIStats_mni ] || mkdir ROIStats_mni
for file in $(find /data/Luna1/Reward/Rest -name rest_preproc_mni.nii.gz); do
   subj_date=$(perl -le 'print "$+{id}_$+{date}" if $ARGV[0] =~ /[^0-9]*(?<id>\d{5})[^0-9]*(?<date>\d{8})/' $file)
   pptype=$(basename $(dirname $file))
   pptype=${pptype/preproc/}
   pptype=${pptype/rest/}
   #pptype=${pptype/torque/}
   pptype=${pptype/_/}
   
   #[ -r ROIStats_mni.1D ] && echo "completed" && continue
   # use nzmean instead of mean (ignore the bits of the ROI out of collected data)?
   #
   3dROIstats -nzmean -nomeanout -numROI 264 -quiet -mask $bb244 $file > ROIStats_mni/${subj_date}_$pptype.1D
done

