#! /bin/bash


# runKMC [seqPath ['kVal list']]

seq=GCF_000002985.6_WBcel235_genomic.fna

# kval=$(seq 4 4 32)
kval="19 28 38 55"

# discount.sh [[seqPath] kLen]
case $# in
    2)
	seq=$1
	kval=$2
	;;
    1)
	seq=$1
	;;
    0)
	;;
    *)
	echo "usage: $0 [seqPath ['kVal list']]"
	exit -1
esac

format="%U user %S system %E elapsed %P CPU (%X text + %D data %M max)k %I inputs + %O outputs (%F major + %R minor)pagefaults %W swaps"

tmpDir=./ttt
if [ -d "$tmpDir" ]; then
    rm -fr "$tmpDir"
fi
filename="${seq##*/}"     # elimina la path
ext="${filename##*.}"     # prende l'estensione
name="${filename%.*}"     # elimina l'estensione

suffix=$(date '+%s')
logFile="run-$name-$suffix.log"
times="times-$name-$suffix.txt"

for k in $kval ; do

    mkdir "$tmpDir"
    out="$tmpDir/${name}-k=$k"
    dump="$out.txt"

    cmd1="kmc -b -hp -k$k -m20 -t8 -fm -ci0 -cs1048575000 -cx2000000000 \
    	     $seq $out ttt"
    cmd2="kmc_dump $out $dump"

    echo $cmd1 >> $logFile
    echo $seq, $k, $(date)
    echo -n "$seq $k " >> $times
    /usr/bin/time --format "$format" --output $times --append $cmd1 >> $logFile 2>&1 

    echo $cmd2 >> $logFile
    echo $seq, $k, $(date)
    echo -n "$seq $k " >> $times
    /usr/bin/time --format "$format" --output $times --append $cmd2 >> $logFile 2>&1

    rm -fr "$tmDir"
done
