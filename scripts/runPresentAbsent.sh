#! /bin/bash

if (( $# != 2)); then
    echo "Usage: $0 seqLen mainDataDir"
    exit -1
else
    seqLen=$1
    dataDir=$2
fi


cmd="spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	     --num-executors 48 --executor-memory 27g --executor-cores 7 \
	     Py-Scripts/PySparkPresentAbsent4.py $seqLen $dataDir"


logFile="run-${seqLen}-$(date '+%s').log"

echo $cmd > $logFile

$cmd >> $logFile 2>&1 
