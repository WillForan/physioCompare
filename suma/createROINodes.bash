#!/usr/bin/env bash

cat > vis/ROIs.niml.do  << EOF 
<nido_head default_color = '0 0 0 1' default_font = 'he18' />
EOF

cat ../txt/bb244_coordinate| 
while read x y z n ; do
 echo "$x $y $z $n"
 cat >> vis/ROIs.niml.do  << EOF 
   <S 
   coord = '$x $y $z'
   col = '0 0 0'
   coord_type = 'fixed'
   rad = '1'
   line_width = '1.5'
   style = 'fill'
   stacks = '20'
   slices = '20'
   />
EOF

done
