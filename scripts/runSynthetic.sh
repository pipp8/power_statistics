#! /bin/bash

# esegue lo script PyPASingleSequenceOutOfMemory.py solo per confrontare sequenze sintetiche
# allontanate con lo script sequenceDistance.py per un fattore theta

scriptDir='/home/cattaneo/spark/power_statistics/Py-Scripts'
dataDir='/home/cattaneo/spark/power_statistics/Datasets'
binCommand='/usr/local/bin/sequenceDivergence'
# dataDir=/mnt/VolumeDati1/Dataset/PresentAbsentDatasets/ncbi_dataset
remoteDataDir=data/semiSynthetics
baseSeq=GCA_000146045.2_R64_genomic.fna
# baseSeq='GCF_000001405.40_GRCh38.p14_coding-all.fna' # homo-sapiens coding sequence
# baseSeq=fish1.fna

seq2='synthetic'

if (( $# < 2)) || (($# > 4)); then
    echo "Usage: $0 sequence remoteDataDir [theta [k]]"
    exit -1
else
    if (($# >= 2)) ; then
	baseSeq=$1
	remoteDataDir=$2
	# thetaValues='0.05 0.10 0.20 0.30 0.40 0.50'
	thetaValues='0.005 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 0.95'
	kValue=""
    fi
    if (($# >= 3)) ; then
	thetaValues=$3
    fi
    if (($# >= 4)) ; then
	kValue=$4
    fi
fi

seq1=${dataDir}/$baseSeq


logFile="run-$(date '+%s').log"
echo "Start Log file: $(date)e" > $logFile
echo "Log file: $logFile"

for i in $thetaValues ; do

    # $binCommand  ${seq1} $i
    # seq2=$(printf "%s/%s-T=%.3f.fna" ${dataDir} $(basename $seq1 .fna) $i)
    
    cmd="spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	     --num-executors 48 --executor-memory 27g --executor-cores 7 \
	     ${scriptDir}/PyPASingleSequenceOutMemory.py $seq1 $seq2 --theta $i --remoteDir $remoteDataDir"
    
    echo "$(date) Comparing $seq1 vs $seq2, Theta = $i, results: $remoteDataDir"
    echo "$(date) Comparing $seq1 vs $seq2 Theta = $i" >> $logFile
    $cmd >> $logFile

done


base=$(basename $baseSeq .fna)
t=0.005
tt=$(printf "%s/%s-%s-T=%.3f-T=%.3f*.csv" $dataDir $base $base $t $t)
report=$(mktemp)

# salva l'header
head -1 $tt > $report
i=0
for f in ${dataDir}/${base}-${base}*.csv; do
    # f=$(printf "%s-%s-T=%.3f-T=%.3f*.csv" $base $base $t $t)
    echo -n "Processing file: $f -> "
    # aggiunge i risultati per ogni theta (senza header)
    tail +2 $f >> $report
    wc -l $report
    ((i++))
done

l=$(wc -l $report | cut -d ' ' -f 1)
# 8 x i + 1
tot=$((i * 8 + 1))
if (($l != $tot)); then
   echo "wrong number of lines $l"
   wc ${dataDir}/${base}*.csv
else
    echo $base ok $l
fi

final=${dataDir}/${base}-$(date +%s).csv

mv $report $final

