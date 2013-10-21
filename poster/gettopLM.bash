#!/usr/bin/env bash
set -x
savedir=imgs/LM
origdddir=../imgs/lm/ageinv/datadriven
[ -r $savedir ] && rm -r $savedir
mkdir -p $savedir
#for d in devel datadriven; do
for d in devel; do
 for f in  ../imgs/lm/ageinv/$d/0[1-4]*; do
   n=$(basename $f)
   linkas=$savedir/$d-${n%%_*}-${n##*-}
   #ln -s $f $linkas
   cp $f $linkas
   echo "$f -> $linkas" >> imagelist
 done
done

while read t f; do
 for ff in $origdddir/$f*; do
  echo $ff
  cp $ff $savedir/datadrive-$t.${ff##*-}
 done
done < datadrivenExamples.txt
