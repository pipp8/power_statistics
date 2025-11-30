#! /bin/bash

scriptDir='/home/cattaneo/spark/power_statistics/Py-Scripts'
dataDir='/home/cattaneo/spark/power_statistics/Datasets'
# dataDir=/mnt/VolumeDati1/Dataset/PresentAbsentDatasets/ncbi_dataset
remoteDataDir=data/test

seq1=${dataDir}/GCF_003339765.1_Mmul_1.0.fasta
seq2=${dataDir}/GCF_000955945.1_Caty_1.0.fasta
kValue=$(seq 4 4 32)

if (( $# == 0));  then
   echo "comparing ${seq1}, ${seq2}, k=$kValue"
elif (( $# == 2)); then
    seq1=$dataDir/$1
    seq2=$dataDir/$2
elif (( $# == 3)); then
    seq1=$dataDir/$1
    seq2=$dataDir/$2
    remoteDataDir=$3
elif (( $# == 4)); then
    seq1=$dataDir/$1
    seq2=$dataDir/$2
    remoteDataDir=$3
    kValue=$4
else
    echo "Usage: $0 sequence1 sequence2 remoteDataDir [k]"
    exit -1
fi


logFile="run-$(date '+%s').log"
echo "Start Log file: $(date)e" > $logFile
echo "Log file: $logFile"

cmd="spark-submit --master yarn --deploy-mode client --driver-memory 27g \
     --num-executors 48 --executor-memory 27g --executor-cores 7 \
     ${scriptDir}/PyPASingleSequenceOutMemory.py $seq1 $seq2 $i $remoteDataDir $kValue"
    
echo "$(date) Comparing $seq1 vs $seq2"
echo "$(date) Comparing $seq1 vs $seq2" >> $logFile
$cmd >> $logFile
