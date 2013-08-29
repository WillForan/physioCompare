#!/usr/bin/env bash
set -e

# get params (from e.g. skynet.cfg)
scriptdir=$(cd $(dirname $0);pwd)
source  $scriptdir/$(hostname).cfg
# loads DataRoot physioppDir nophysioppDir unbettedRefBrain subjexample


cd $(dirname $0)
[ -d txt ] || mkdir txt


# participant list is 
#  subj_date preproc_torque{,_nophysio} filepath
#
#if [ ! -r txt/subject_list.txt ] ; then
  for file in $( find $DataRoot -name rest_preproc_mni.nii.gz ) ; do
     subj_date=$(perl -le 'print "$+{id}_$+{date}" if $ARGV[0] =~ /[^0-9]*(?<id>\d{5})[^0-9]*(?<date>\d{8})/' $file)
     # maybe this is just subject (no date) ... gross
     [ -z "$subj_date" ] && subj_date=$(perl -le 'print "$+{id}" if $ARGV[0] =~ m:/(?<id>\d{5})/:' $file)
  
     # otherwise this guys is just no where, so skip
     [ -z "$subj_date" ] && echo "skipping. bad file? $file" >&2 && continue
  
     pptype=$(basename $(dirname $file))
     echo -e "$subj_date\t$pptype\t$file"
  done |egrep "$physioppDir|$nophysioppDir" | tee txt/subject_list.txt
  
  echo; echo;
#fi 

# give perl access to dir types
export physioppDir nophysioppDir
# make a compact table of everyone we have
perl -MList::Util -slane '
BEGIN{
 @types=@ENV{qw/physioppDir nophysioppDir/};
 print join("\t","subj_date",@types);
}
 # F0 is subject, 1 the pipline, 2 file
 $a{$F[0]}{$F[1]}=$F[2];
 END{ 
 # print what subjects have at least 2 pipelines (all of them currently)
 for my $subj (keys %a){ 
   @values=map{ $a{$subj}{$_}?1:0} @types;
   print join("\t",$subj, @values) if List::Util::sum(@values)>1;
 }
}' txt/subject_list.txt | tee txt/subjINpipelines.txt
