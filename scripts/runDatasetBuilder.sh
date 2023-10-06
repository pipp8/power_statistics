#! /bin/bash

# SeqLen=1000
# while [ $SeqLen -le 15000 ]; do
#    echo "running for len= $SeqLen"
#    ((SeqLen+=1000))
# done

destDir='data/dataset10-1000/len=$1'
start=1000
last=1000
step=2000
numPairs=1000
geneSize=3
patternSize=32


if (( $# > 0)); then
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
fi
spark-submit --class it.unisa.di.bio.DatasetBuilder \
	     --master yarn --deploy-mode client --driver-memory 16g \
	     --num-executors 4 --executor-memory 27g --executor-cores 7 \
	     target/powerstatistics-1.3-SNAPSHOT-jar-with-dependencies.jar \
	     --output $destDir --generator eColiShuffled --mode yarn\
             --from-len $start --to-len $last --step $step \
             --pairs $numPairs  --geneSize $geneSize \
             --patternSize $patternSize -f
