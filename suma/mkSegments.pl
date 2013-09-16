#!/usr/bin/env perl

use strict;
use warnings;
use Text::CSV;
use File::Basename;
use Data::Dumper;
# for colors
use Color::Spectrum::Multi;
use Number::RGB;
# to write out a spectrum
use GD;
use Getopt::Std;
#use v5.14;

######
# 
# generate segments between rois
#
# - read in roi coordinates
# - get roiXroi model info, match to cooridnates
# - truncate based on percent that we want to show
#
# - make node file
#    - count roi's involved, 
# - make spectrum
#   - based on max/min r value
# - make edge file
#   - color based on spectrum
#   - print endpoints (both cords) color (r g b) opacity and width
#
#####

my %opts=(
      i=>'../txt/ageeffAgeXphys-invage.csv', # input/node file
      s=>'ageXphysio.tval',            # sort field
      v=>'ageXphysio.val',             # value field
      p=>'.01',                        # percent shown
      #t=>'-9999',                     # sort field threshold, intentionally left undefined bu default
      c=>'100',                        # number of colors
      #tx=>'4',                        # max tval
      #tn=>'.5',                       # min tval
      l=>'5');                         # line width at max

# b is ballanced spectrum
getopts('i:s:p:l:c:v:t:b',\%opts);


### parse inputs
my $sortField=$opts{s};
my $valueField=$opts{v};
my $percent=$opts{p};
$precent=1 if exists $opts{t}; # don't truncated data based on percent, but based on a threshold
my $maxwidth=$opts{l};
my $balenced=exists($opts{b})?'balenced':'unbalenced';
my $maxrad=3;
my $numcolors=$opts{c};
my @colors=Color::Spectrum::Multi::generate($numcolors+1,'#FF0000','#FFFF00');
# if unbalanced use the same spectrum, otherwise use a spectrum with a middle
my @valcolors=Color::Spectrum::Multi::generate($numcolors+1,'#FF0000','#FFFF00');
if(exists($opts{b})){
  @valcolors=Color::Spectrum::Multi::generate($numcolors+1,'#FF0000','#FFFF00','#00FFFF');
}

## setup outputs
my $outid= basename($opts{i},qw/.csv .txt .tsv/)."-$balenced-colorby${valueField}_width$sortField-p$percent";
$outid.="-t$opts{t}" if exists $opts{t};
my $outputDOfilename        = "vis/Edges-$outid.1D.do";
my $outputNodefilename      = "vis/Nodes-$outid.niml.do";
my $outputNodeCountfilename = "../txt/nodecounts-$outid.txt";
my $outputSpectrumfilename  = "vis/Spectrum-${outid}";
# MAX and MIN will be s/// replace

## ROIS -- need number and xyz postion
my %roi;
open my $csvfile, "<", "../txt/bb244_coordinate";
while(<$csvfile>){
 chomp;
 my ($x,$y,$z,$n)=split/\t/;
 $roi{$n}->{xyz}=join(" ",$x,$y,$z);
 $roi{$n}->{count}=0;
}

## extract ROI-ROI values, add xyz to each ROI
my $csv = Text::CSV->new;
open my $modelcsv, "<", $opts{i};
my $names=$csv->getline($modelcsv);
my (%values, @values);
while(my $row=$csv->getline($modelcsv)){
 $values{$names->[$_]} = $row->[$_] for 0..$#{$row};
 $values{"ROI${_}xyz"} = $roi{$values{"ROI$_"}}->{xyz} for (1,2);
 push @values,{%values};
}
close($modelcsv);

# sort 
my @valuessorted = sort {$b->{$sortField} <=> $a->{$sortField}} @values; 

# truncate to only use the percent we're told to
if($percent<1) {
 @valuessorted = @valuessorted[0..int($percent*$#valuessorted)];
}
# remove those below (abs of) threshold
if($opts{t}){
    @valuesorted = grep {abs($_->{$sortField}) >= $opts{t}} @valuesorted
}

## NODES
# count roi hits
for my $ref (@valuessorted){
 $roi{$ref->{"ROI$_"} }->{count}++ for (1,2);
}

# remove unused nodes and build max/min
my $max=0;my $min=99;
my @keep = grep {my $count=$roi{$_}->{count};$min=$count<$min?$count:$min;$max=$count>$max?$count:$max; $count>0} (keys %roi);
%roi = map { $_ => $roi{$_} } @keep;
print "node: max:$max, min: $min\n";
# storing all information in this file name -- silly
my $nodemax=$max;

# write out nodefile
open my $nodeouttxt, '>', $outputNodeCountfilename;
open my $nodeout, '>', $outputNodefilename;
print $nodeout "<nido_head default_color = '1.0 1.0 1.0 1' default_font = 'he18' />\n";
for my $rn (sort {$b<=>$a} keys %roi){
 my $xyz=$roi{$rn}->{xyz};
 my $count=$roi{$rn}->{count};
 # how many inteval per step * number of steps
 my $colorstep=int( ($count-$min)/($max-$min) * $numcolors);
 # colors go max to min
 $colorstep= $numcolors - $colorstep;
 my $color= join(" ", map {$_/256} @{Number::RGB::rgb( Number::RGB->new( hex=> $colors[$colorstep] ) ) });

 my $rad = ($count-$min)/($max-$min) * $maxrad + .1;
 print $nodeout " <S coord = '$xyz' col = '$color' ";
 print $nodeout "coord_type = 'fixed' rad = '$rad' line_width = '1.5' style = 'fill' stacks = '20' slices = '20' />\n";

 print $nodeouttxt join("\t",$rn, @{$roi{$rn}}{qw/count xyz/}),"\n"; 
}
close($nodeout);
close($nodeouttxt);




#### SEGMENTS
# generate color map for segments
my $totalused = $#valuessorted;
my $tvalmax=$valuessorted[0]->{$sortField};
my $tvalmin=$valuessorted[$totalused]->{$sortField};
my ($valmin,$valmax)=(99,0);
for my $ref (@valuessorted) {
  my $val=$ref->{$valueField};
  $valmin=$val<$valmin?$val:$valmin;
  $valmax=$val>$valmax?$val:$valmax;
}
print "edge: tmax:$tvalmax\ttmin: $tvalmin\n    vmax: $valmax\tvmin:$valmin\n";
# use a balanced spectrum so 0 is at the same place
if(exists($opts{b})){
 $max=$valmax>abs($valmin)?$valmax:abs($valmin);
 $valmin=-$max; $valmax=$max;
}

# setup output file
open my $segmentout, ">", $outputDOfilename;
print $segmentout "#segments\n";

# loop through all the values we want to see (top $opt{p} percent)
my $i=0;
while($i++ < $totalused ){
 # get the color for this guy
 my $tvalue=$valuessorted[$i]->{$sortField};
 my $value=$valuessorted[$i]->{$valueField};
 #my $colorstep=int( ($tvalue-$tvalmin)/($tvalmax-$tvalmin) * $numcolors);
 my $colorstep=int( ($value-$valmin)/($valmax-$valmin) * $numcolors);
 # colors go tvalmax to min
 $colorstep= $numcolors - $colorstep;
 # suma wants r g b each as a value from 0 to 1
 my @rgb=map {$_/256} @{Number::RGB::rgb( Number::RGB->new( hex=> $valcolors[$colorstep] ) ) };
 # print endpoints (both cords) color (r g b) opacity and width
 my $width= ($tvalue-$tvalmin)/($tvalmax-$tvalmin) * $maxwidth + .1;
 print $segmentout join(" ",@{$valuessorted[$i]}{qw/ROI1xyz ROI2xyz/}, @rgb, 1, $width),"\n";
}
close($segmentout);

#### Spectrum imgs
# Make color spectrum for segments
GD::Image->trueColor(1);
my $imTN = new GD::Image(1,$numcolors);
my $imV = new GD::Image(1,$numcolors);
for $i (0..$#colors){
  my @rgb   = @{Number::RGB::rgb( Number::RGB->new( hex=> $colors[$i] ) ) }; 
  my $color = $imTN->colorAllocate(@rgb);
  $imTN->setPixel(0,$i,$color);

  @rgb   = @{Number::RGB::rgb( Number::RGB->new( hex=> $valcolors[$i] ) ) }; 
  $color = $imTN->colorAllocate(@rgb);
  $imV->setPixel(0,$i,$color);
}
open my $imgout, '>', $outputSpectrumfilename."V${valmax}_${valmin}.png";
print $imgout $imV->png;
close $imgout;

open $imgout, '>', $outputSpectrumfilename."T${tvalmax}_${tvalmin}_N${nodemax}.png";
print $imgout $imTN->png;
close $imgout;

print <<HEREDOC
 $outputDOfilename
 $outputNodefilename;
 $outputNodeCountfilename;
 $outputSpectrumfilename
HEREDOC


