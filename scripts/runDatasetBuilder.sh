#! /bin/bash

# SeqLen=1000
# while [ $SeqLen -le 15000 ]; do
#    echo "running for len= $SeqLen"
#    ((SeqLen+=1000))
# done

destDir='data/datasetSmall-1000'
start=10000
last=10000
step=20000
numPairs=1000


case $# in
    1)
	destDir=$1
	;;
    2)
	destDir=$1
	start=$2
	;;
    3)
	destDir=$1
	start=$2
	last=$3
	;;
    4)
	destDir=$1
	start=$2
	last=$3
	step=$4
	;;
    5)
	destDir=$1
	start=$2
	last=$3
	step=$4
	numPairs=$5
	;;
    *)
	echo "Usage: $0 [destDir[start[last[step[#pairs]]]]]"
	exit -1
	;;
esac

spark-submit --class it.unisa.di.bio.DatasetBuilder \
	     --master yarn --deploy-mode client --driver-memory 16g \
	     --num-executors 4 --executor-memory 27g --executor-cores 7 \
	     target/powerstatistics-1.0-SNAPSHOT.jar \
	     $destDir detailed yarn $start $last $step $numPairs

