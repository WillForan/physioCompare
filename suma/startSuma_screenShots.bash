#!/usr/bin/env bash

##
# - start suma if not started
# - take shots of node and edge file with the given pattern
#    - path is relative to suma directory
#
# USEAGE: sumaTogglefile.sh <edge/node prefix>
#    e.g. ./sumaTogglefile.sh vis/ageeffAgeXphys-invage-unbalenced-colorbyageXphysio.val_widthageXphysio.tval-p1-t2.596
# 
#    first argument is prefix for node and edge file
#    edge is 1D.do
#    node is niml.do
#    
#    to use a spefile
#    specFile=my.spec ./sumaTogglefile.sh
# 
#
# * make reused temp file 
# * list files matching DOwildcard
# * replace/load selected Displayable Objects file
#
##END
function helper { 
 sed -n 's/# //p;/##END/q' $0;
 exit 
}

# start from suma dir
cd $(dirname $0)

[ -z "$1" -o -n "$2" ] && echo -e "***
Bad arguments? Try ./ for current dir
make sure *,{},etc are trapped/escaped (e.g '*DO' not just *DO)
if matching two globs, put both in same quote pair ('*DO *do')
***" 1>&2 && helper


# make path absolute glob after dir will still mess it up (e.g. if vis/, vis* won't work)
path=$1; [ -z "$path" ] && echo "need a file prefix" && exit 1


# specfile and subject volume not set? set it
[ -z "$specFile" ] && specFile=~/standard/suma_mni/N27_both.spec          # ziad's
#[ -z "$specFile" ] && specFile=~/standard/colin27/SUMA/colin27_both.spec # michael's
echo using specfile $specFile

# do we want to tie to afni?
if [ -n "$AFNI" ]; then
   # set nifti file
   [ -z "$afniFile" ] && afniFile=~/standard/suma_mni/MNI_N27+tlrc # ziad's
   #[ -z "$afniFile" ] && afniFile=~/standard/colin27/SUMA/brain.nii    # michael's
   echo using afni $afniFile

   # run suma linked to afni
   additSuma="-sv $afniFile"

   # run afni
   xterm -e "afni -niml $afniFile" &
fi


# check sanity of input
nodefile=$path-Nodes.niml.do
edgefile=$path-Edges.1D.do
for fn in $nodefile $edgefile; do
  [ ! -r "$fn" ] && echo "no $fn" && exit 1
  echo using $fn
done

# run suma if it's not already running
if [ -z "$(ps x -o command | grep ^suma)" ]; then
 xterm -e "suma -niml -spec $specFile $additSuma" & 
 echo "started suma, sleeping for 20 secs"
 sleep 20
 # widnow size, zoom, cursor off, background white
 DriveSuma -echo_edu -com viewer_cont  \
     -key F3 \
     -key F6 \
     -key:r:3 z \
     -viewer_size 1024 800
 
fi
# run afni?

#make the temp file and store it's location
temp="$(mktemp .tmpXXX.niml.do)"
function showTempNiml {
   DriveSuma -echo_edu -com viewer_cont -load_do "$temp"
}




#### show colored nodes 
cat $nodefile > $temp
showTempNiml
./sumaSnapshot.sh coloredROIonly-$(basename $path)

#### show edges (colored)
cat $edgefile > $temp
showTempNiml
./sumaSnapshot.sh coloredROI-$(basename $path)


#### show black nodes on top of colored nodes
cat  $nodefile <(sed "/nido_head/d; s/rad = '1'/rad = '.5'/" vis/ROIs.niml.do) > $temp
showTempNiml
./sumaSnapshot.sh allROIwithColor-$(basename $path)

# clear nodes, show only black
echo -e "<nido_head />" > $temp 
showTempNiml
cat vis/ROIs.niml.do > $temp
showTempNiml
./sumaSnapshot.sh blackROI-$(basename $path)

# clean up 
rm $temp
# clear edges
echo -e "#segment\n87 -120 108 87 -120 108 0 0 0 0 0" > $temp
showTempNiml
# clear nodes
echo -e "<nido_head />" > $temp 
showTempNiml
