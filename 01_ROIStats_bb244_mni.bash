#!/usr/bin/env bash

#########
# 
# get bb244 rois average per time point
# from subjects mni warp
# 
#########

set -e
cd $(dirname $0)

      bb244=bb244MNI_LPI_2mm.nii.gz
subjectlist="txt/subject_list.txt"
uselist="txt/subjINpipelines.txt"
    savedir="txt/bb244Stats_mni/"


# drake should take care of this?
[ ! -r $subjectlist ] && ./00_table.bash   # create subjectlist
[ ! -r $bb244 ] && ./00_bb244MNImask.bash  # create b244 mask
[ -d $savedir ] || mkdir -p $savedir          # creat save directory


cat $subjectlist | while read subj_date pptype file ; do
   [ -z "$pptype" -o -z "$subj_date" ] && echo "subj '$subj_date' or type '$pptype' empty, skipping" && continue
   savename=$savedir/${subj_date}_$pptype.1D
   [ -r $savename ] && echo "completed $subj_date $pptype already" && continue
   ! grep $subj_date $uselist  && echo "$subj_date $pptype not in $uselist" &&  continue
   # use nzmean instead of mean (ignore the bits of the ROI out of collected data)?
   #
   # use 256 instead of 244 as ROIs are labeled to 264 -- this gives us predicatable output
   3dROIstats -nzmean -nomeanout -numROI 264 -quiet -mask $bb244 $file > $savename
done

