#! /bin/bash

tmp=/tmp/aa.$$
path=data/dataset5-1000

if [ $# -ne 4 ]; then
    echo "errore cattivo numero di argomenti $#"
    echo "Usage: runCafe.sh seq1 seq2 k results"
    exit -1
fi

seq1=$1
seq2=$2
k=$3
results=$4
results2=$(dirname $4)/$(basename $4 .csv)-values.csv

echo "Processing $(basename $seq1 .fasta), $(basename $seq2 .fasta), k=$3, results=$(basename $results)"

cafe-mod -R -K $k -J /usr/local/bin/jellyfish -D jaccard -I $seq1,$seq2 > $tmp
line=$(tail -n 5 $tmp | head -1)
f1=$(echo $line | cut -d ' ' -f 1-1)
d=$(echo $line | cut -d ' ' -f 3-3)
if [ "$f1.fasta" != $(basename "$seq1") ]; then
    echo "cafe failed!!! see file $tmp"
    exit -1
else
    echo $seq1,$seq2, $d >> $results
    line2=$(tail -n 9 $tmp | head -1)
    echo $line2 >> $results2
fi
rm $tmp

