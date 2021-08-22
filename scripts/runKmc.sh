#! /bin/bash

scDir='/Users/pipp8/Universita/Src/IdeaProjects/PowerStatistics/scripts'

if [ "$#" -lt 1 ]; then
    files=*.fasta
else
    files=$1
fi


for f in $files; do
    echo $f
    # for k in 4 6 8 10; do
    for k in 4 6; do
	echo k = $k
	kmc -k$k -m2 -fm -ci0 -cs1000000 -n77 $f tt ./tmp
	base=$(basename $f .fasta)
	outFile=distk=${k}_${base}.hist
	kmc_dump tt $outFile

	$scDir/hist2dist-kmc.py $outFile
    done
done

