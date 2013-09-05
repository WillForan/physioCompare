#!/usr/bin/env bash

# see ./startSuma_chooseSegments.bash to start suma
# take shots of the brain in suma
# white F6
# no Xhair F3
# full brain (no "p" pushes)

date=$(date +%F-%H:%M)


inputref=$1
[ -z "$inputref" ] && echo 'describe me: ' && read inputref;


for hem in full half; do 
 
 DriveSuma -com viewer_cont    -key r   
 DriveSuma -com viewer_cont    -key:3r p
 DriveSuma -com recorder_cont -save_as ../imgs/suma/$inputref-$hem-fullbrain-$date.jpeg
 # most no brain
 DriveSuma -com viewer_cont   -key p -key p -key r
 DriveSuma -com recorder_cont -save_as ../imgs/suma/$inputref-$hem-almostnobrain-$date.jpeg
 # no brain
 DriveSuma -com viewer_cont   -key p -key r
 [ $hem == full ] && DriveSuma -com recorder_cont -save_as ../imgs/suma/$inputref-nobrain-$date.jpeg
 DriveSuma -com viewer_cont    -key "]"
done
#DriveSuma -com viewer_cont    -key "]"
# reset
#DriveSuma -com viewer_cont   -key p -key p

#DriveSuma -com viewer_cont   -key:3r p                        # move brain a bit
#DriveSuma -com viewer_cont   -key right   -key r              # move brain a bit
#
#DriveSuma -com viewer_cont   -key ctrl+up -key r              # top view
#DriveSuma -com recorder_cont -viewer_size 800 600             # resise (only onece)
#DriveSuma -com recorder_cont -save_as img/tmp$date.jpeg           # save
#
#DriveSuma -com viewer_cont  -key ']' -key ctrl+left  -key r   # only one hempisphere, left side
#DriveSuma -com recorder_cont -save_as img/tmp$date.jpeg       # save
#
#DriveSuma -com viewer_cont           -key ctrl+right -key r   #                       right side
#DriveSuma -com recorder_cont -save_as img/tmp$date.jpeg       # save

#convert  tmp2012-04-25.00001.jpg -transparent black result.png
# not convert -matte tmp2012-04-25.00001.jpg -fill none -fuzz 3% -opaque black  result.png
#
#composite -gravity northeast -background none ../vis/*svg result.png test.png


