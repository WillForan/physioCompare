#!/usr/bin/env bash

# used primarly by startSuma_screenShots.bash
#
# takes screenshots of suma with different brain displays
#


date=$(date +%F-%H:%M)


inputref=$1
[ -z "$inputref" ] && echo 'describe me: ' && read inputref;

rm ../imgs/suma/*$inputref-{Node,Edge,Spectrum}*.jpg

for hem in full half; do 
 
 # opaque brain (full and half)
 DriveSuma -com viewer_cont  -key p -key r

 [ "$hem" == "half" ] && DriveSuma -com viewer_cont    -key "[" -key r
 sleep 1
 DriveSuma -com viewer_cont  -key r
 DriveSuma -com recorder_cont -save_as ../imgs/suma/$hem-opaquebrain-$inputref.jpg
 [ "$hem" == "half" ] && DriveSuma -com viewer_cont    -key "["
 echo "$hem opaque"


 # reset transparency
 DriveSuma -com viewer_cont   -key p -key p -key p 

 # half brain
 if [ "$hem" == "half" ]; then 
   echo "using half!"
   DriveSuma -com viewer_cont   -key "[" -key r
   sleep 1
   DriveSuma -com viewer_cont  -key r
   DriveSuma -com recorder_cont -save_as ../imgs/suma/$hem-$inputref.jpg 
   DriveSuma -com viewer_cont  -key "[" 
   continue
 fi


 # no brain
 echo "no brain pictures"
 DriveSuma -com viewer_cont  -key "[" -key "]"  -key r
 sleep 1
 DriveSuma -com viewer_cont  -key r
 DriveSuma -com recorder_cont -save_as ../imgs/suma/nobrain-$inputref.jpg
 DriveSuma -com viewer_cont    -key "[" -key "]"

done

# remove suma numbering of screenshots
cd ../imgs/suma
for f in *$inputref*; do mv $f ${f/.[0-9][0-9][0-9][0-9][0-9].jpg/.jpg}; done
