
#! /bin/bash

# SeqLen=1000
# while [ $SeqLen -le 15000 ]; do
#    echo "running for len= $SeqLen"
#    ((SeqLen+=1000))
# done

start=100000
last=10000000
step=200000

case $# in
    1)
	start=$1
	;;
    2)
	start=$1
	last=$2
	;;
    3)
	start=$1
	last=$2
	step=$3
	;;
    *)
	echo "Usage: $0 [start[last[step]]]"
	exit -1
	;;
esac

spark-submit --class it.unisa.di.bio.DatasetBuilder \
	     --master yarn --deploy-mode client --driver-memory 16g \
	     --num-executors 4 --executor-memory 27g --executor-cores 7 \
	     target/powerstatistics-1.0-SNAPSHOT.jar \
	     data/test detailed yarn $start $last $step


