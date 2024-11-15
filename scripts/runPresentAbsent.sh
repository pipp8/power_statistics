#! /bin/bash


if (( $# != 3 )); then
    echo "Usage: $0 seqLen mainDataDir local|yarn"
    exit -1
else
    seqLen=$1
    dataDir=$2
    executionMode=$3

    if [[ $executionMode != "local" && $executionMode != "yarn" ]]; then
        echo "Please specify execution mode as either 'local' or 'yarn'"
        exit -1
    fi
fi

cmd="spark-submit --master $executionMode --deploy-mode client --driver-memory 27g"

# Configure executors only for yarn mode
if [[ $executionMode == "yarn" ]]; then
    cmd="$cmd --num-executors 48 --executor-memory 27g --executor-cores 7"
fi

cmd="$cmd Py-Scripts/PySparkPresentAbsent4.py $seqLen $dataDir"

logFile="run-${seqLen}-$(date '+%s').log"

echo $cmd > $logFile

$cmd >> $logFile 2>&1 
