#!/usr/bin/env bash
set -e
cd $(dirname $0)
[ -d txt ] || mkdir txt


# participant list is 
#  subj_date preproc_torque{,_nophysio} filepath
#
for file in $( find /data/Luna1/Reward/Rest -name rest_preproc_mni.nii.gz ) ; do
   subj_date=$(perl -le 'print "$+{id}_$+{date}" if $ARGV[0] =~ /[^0-9]*(?<id>\d{5})[^0-9]*(?<date>\d{8})/' $file)
   [ -z "$subj_date" ] && echo "skipping. bad file? $file" >&2 && continue
   pptype=$(basename $(dirname $file))
   echo -e "$subj_date\t$pptype\t$file"
done | tee txt/subject_list.txt

echo; echo;

perl -slane '
BEGIN{
 @types=qw/preproc_torque_nophysio preproc_torque/;
 print join("\t","subj_date",@types);
}
 $a{$F[0]}{$F[1]}=$F[2];
 END{ 
 for my $subj (keys %a){ 
   print join("\t",$subj,map{ $a{$subj}{$_}?1:0} @types );
 }
}' txt/subject_list.txt | tee txt/subjINpipelines.txt
