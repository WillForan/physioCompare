#!/usr/bin/env perl

use strict;
use warnings;
use Text::CSV;
use Data::Dumper;
# for colors
use Color::Spectrum::Multi;
use Number::RGB;
# to write out a spectrum
use GD;
#use Getopt::Std;
#use v5.14;

######
# 
# generate segments between rois
# - read in roi coordinates
# - get roiXroi model info, match to cooridnates
# - print endpoints (both cords) color (r g b) opacity and width
#
#####

my %opts=(
      i=>'../txt/ageeffAgeXphys-invage.csv', # input/node file
      s=>'ageXphysio.tval',            # sort field
      p=>'.01',                        # percent shown
      l=>'1');                         # line width

getopts('i:',\%opts);


my $field=$opts{s};
my $percent=$opts{p};
my $width=$opts{l};
my @rgb=qw/1 1 1/;

#
#
my %roi;
open my $csvfile, "<", "../txt/bb244_coordinate";
while(<$csvfile>){
 chomp;
 my ($x,$y,$z,$n)=split/\t/;
 $roi{$n}=join(" ",$x,$y,$z);
}


my $csv = Text::CSV->new;
open my $modelcsv, "<", $opt{i};
my $names=$csv->getline($modelcsv);
my (%values, @values);
while(my $row=$csv->getline($modelcsv)){
 $values{$names->[$_]} = $row->[$_] for 0..$#{$row};
 $values{"ROI${_}xyz"} = $roi{$values{"ROI$_"}} for (1,2);
 push @values,{%values};
}

# sort 
my @valuessorted = sort {$a->{$field} <=> $b->{$field}} @values; 

# generate color map
my $totalused = int($percent*$#valuessorted);
my @color=generate($totalused,'#FFFFFF','#333333')

# setup output file
open my $segmentout, ">", "vis/ageXphysio.tval.1D.do";
print $segmentout "#segments\n";

# loop through all the values we want to see (top $opt{p} percent)
my $i=0;
while($i++ <= $totalused ){
# print endpoints (both cords) color (r g b) opacity and width
 print $segmentout join(" ",@{$valuessorted[$i]}{qw/ROI1xyz ROI2xyz/}, @rgb, 1, $width),"\n";
}
