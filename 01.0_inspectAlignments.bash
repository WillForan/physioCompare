#!/usr/bin/env bash

###
# make sure we aling everything well
###

set -xe

# get params (from e.g. skynet.cfg)
scriptdir=$(cd $(dirname $0);pwd)
source  $scriptdir/$(hostname).cfg
# loads $mni

bb244="bb244MNI_LPI_2mm.nii.gz"
subjectlist="$scriptdir/txt/subject_list.txt"

alignmentImages="imgs/alignments"
[ -d $alignmentImages ] || mkdir -p $alignmentImages

# launch fake X
display=190

Xvfb :$display &
xvfbpid=$!
cat $subjectlist | while read subj_date pptype file ; do

   [ -z "$pptype" -o -z "$subj_date" ] && echo "subj '$subj_date' or type '$pptype' empty, skipping" && continue
   #[ -r $alignmentImages/$subj_date-UNDERbb244-$pptype.jpeg  ] && echo "already have picture" && continue
   ! grep $subj_date $scriptdir/txt/subjINpipelines.txt && echo "$subj_date not in subjInpipelines" && continue

   # it does a redudant bit with mni

   AFNI_DETACH=FALSE afni -display :$display  -yesplugouts   \
     -com "SET_UNDERLAY $(basename $mni)" \
     -com "SET_FUNCTION $(basename $file)"  \
     -com "OPEN_WINDOW axialimage mont=6x7:4 geom=800x800 opacity=6" \
     -com "OPEN_WINDOW sagittalimage mont=6x7:4 geom=800x800 opacity=6" \
     -com "OPEN_WINDOW coronalimage mont=7x7:4 geom=800x800 opacity=6" \
     -com 'SET_XHAIRS OFF' -com 'SET_THRESHNEW 0'\
     -com 'SET_FUNC_RANGE .5'  \
     -com "SAVE_JPEG axialimage $alignmentImages/$subj_date-mni-axl.jpg" \
     -com "SAVE_JPEG coronalimage $alignmentImages/$subj_date-mni-cor.jpg" \
     -com "SAVE_JPEG sagittalimage $alignmentImages/$subj_date-mni-sag.jpg" \
     -com 'SET_FUNC_RANGE 264'  \
     -com "SET_UNDERLAY $(basename $file)" \
     -com "SET_FUNCTION $(basename $bb244)"  \
     -com "SAVE_JPEG axialimage $alignmentImages/$subj_date-$pptype-axl.jpg" \
     -com "SAVE_JPEG coronalimage $alignmentImages/$subj_date-$pptype-cor.jpg" \
     -com "SAVE_JPEG sagittalimage $alignmentImages/$subj_date-$pptype-sag.jpg" \
     -com "QUIT" \
     "$file" "$mni" "$bb244"


    convert +append $alignmentImages/$subj_date-mni-*jpg $alignmentImages/$subj_date-OVERmni-$pptype.jpeg 
    convert +append $alignmentImages/$subj_date-$pptype*jpg $alignmentImages/$subj_date-UNDERbb244-$pptype.jpeg 

    rm $alignmentImages/$subj_date*jpg

#break # testing, stop after one 
done

kill $xvfbpid


