#!/usr/bin/env bash

###
# find where in the brain our ROIs are
###
# need txt/bb244_coordinate
###

# cat abuse to give directional flow
# in: coord file is tab delm: x y z roiNumber
# out: tab file: ROInum x y z atlas radius label prob labelNumber
coordfile=txt/bb244_coordinate
atlas=CA_ML_18_MNIA 
space=MNI_ANAT 

output=txt/labels_$(basename $coordfile)
[ -d $(dirname $output) ] || mkdir -p $(dirname $output)

# bsd uniq does not have -w 3 --- compare only the first 3 chars
# want this to display only the closest name to provided point
uniq=uniq
which guniq && uniq=guniq



cat $coordfile|
 while read x y z n; do
   whereami "$x" "$y" "$z" -lpi -space $space -atlas $atlas -tab -max_search_radius 2 2>/dev/null|
    (grep 'CA_ML'||echo -e "$atlas\t-1\tunknown\t0\t0")|
    sed "s/^/$n	$x	$y	$z	/";
  done | $uniq -w 3 |tee $output |column -ts"	"
