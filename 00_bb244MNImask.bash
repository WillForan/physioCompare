#!/usr/bin/env bash
set -e


###
# put roi's into mask so we can apply the roi's to the data
###
# need txt/bb244_coordinate
##

# get params (from e.g. skynet.cfg)
scriptdir=$(cd $(dirname $0);pwd)
source  $scriptdir/$(hostname).cfg
# loads DataRoot physioppDir nophysioppDir unbettedRefBrain subjexample

bb244=bb244MNI_LPI_2mm.nii.gz

### original bb244 might be bad?
#3dcopy -overwrite bb244+tlrc bb244MNI.nii.gz
#3dresample -overwrite -inset bb244MNI.nii.gz -prefix bb244MNI_res.nii.gz -master /Volumes/Serena/Rest/Subjects/10153/pipeTests/bp+ort_noPhysio/rest_preproc_mni.nii.gz
3dUndump -srad 5 -prefix $bb244  -master $subjexample \
            -orient LPI -xyz txt/bb244_coordinate

