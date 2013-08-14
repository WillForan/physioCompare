#!/usr/bin/env bash
set -e

unbettedRefBrain="/data/Luna1/ni_tools/standard_templates/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii"
# N.B. Undumping to this mni brain doesn't work as expected!!

subjexample="/data/Luna1/Reward/Rest/10152_20111123/preproc_torque/rest_preproc_mni.nii.gz"
bb244=bb244MNI_LPI_2mm.nii.gz

### original bb244 might be bad?
#3dcopy -overwrite bb244+tlrc bb244MNI.nii.gz
#3dresample -overwrite -inset bb244MNI.nii.gz -prefix bb244MNI_res.nii.gz -master /Volumes/Serena/Rest/Subjects/10153/pipeTests/bp+ort_noPhysio/rest_preproc_mni.nii.gz
3dUndump -srad 5 -prefix $bb244  -master $subjexample \
            -orient LPI -xyz bb244_coordinate

