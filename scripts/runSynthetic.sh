#! /bin/bash

# esegue lo script PyPASingleSequenceOutOfMemory.py solo per confrontare sequenze sintetiche
# allontanate con lo script sequenceDistance.py per un fattore theta

scriptDir='/home/cattaneo/spark/power_statistics/Py-Scripts'
dataDir='/home/cattaneo/spark/power_statistics/Datasets/experiment-20260926'
binCommand='/usr/local/bin/sequenceDivergence'
remoteDataDir=data/semiSynthetics
baseSeq=GCA_000146045.2_R64_genomic.fna

sequenceList='CElegans.fna HouseMouse.fna Yeast.fna  Chimpazee.fna HomoSapiens.fna MacacaMulatta.fna'
sequenceList='HouseMouse.fna Chimpazee.fna MacacaMulatta.fna'
thetaValues='0.005 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 0.95'
fromK=4
toK=32

seq2='synthetic'

if (($# > 4)); then
    echo "Usage: $0 sequence remoteDataDir [theta [k]]"
    exit -1
else
    # if zero parametri usa i valori di default assegnati alle variabili
    if (($# >= 1)) ; then
	sequenceList=$1
    fi
    if (($# >= 2)) ; then
	remoteDataDir=$2
    fi
    if (($# >= 3)) ; then
	thetaValues=$3
    fi
    if (($# >= 4)) ; then
	fromK=$4
	toK=$4
    fi
fi



for s in $sequenceList; do

    seq1=${dataDir}/$s


    logFile="run-$(date '+%s').log"
    echo "Start Log file: $(date)e" > $logFile
    echo "Log file: $logFile"

    for i in $thetaValues ; do

	# non serve più generato automaticamente da PyPASingleSequenceOutOfMemory.py
	# $binCommand  ${seq1} $i
	# seq2=$(printf "%s/%s-T=%.3f.fna" ${dataDir} $(basename $seq1 .fna) $i)
    
	cmd="spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	     --num-executors 48 --executor-memory 27g --executor-cores 7 \
	     ${scriptDir}/PyPASingleSequenceOutMemory.py $seq1 $seq2 --theta $i --fromSizeK $fromK --toSizeK $toK --remoteDir $remoteDataDir"
    
	echo "$(date) Comparing $seq1 vs $seq2, Theta = $i, results: $remoteDataDir"
	echo "$(date) Comparing $seq1 vs $seq2 Theta = $i" >> $logFile
	$cmd >> $logFile

    done


    base1=$(basename $seq1 .fna)
    base2=$(basename $seq2 .fna)
    t=0.005
    tt=$(printf "%s/%s-%s-T=%.3f*.csv" $dataDir $base1 $base2 $t)
    report=$(mktemp)
    
    # salva l'header
    head -1 $tt > $report
    i=0
    for f in ${dataDir}/${base1}-${base2}*.csv; do
	# f=$(printf "%s-%s-T=%.3f*.csv" $base1 $base2 $t)
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
	wc ${dataDir}/${base1}*.csv
    else
	echo $base1 ok $l
    fi
    
    final=${dataDir}/${base1}-$(date +%s).csv

    mv $report $final
done
