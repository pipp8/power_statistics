#! /bin/bash

destDir='data/dataset10-1000/len=$1'
start=1000
last=1000
step=2000
numPairs=1000
geneSize=1
patternSize=32
prefixPath="data"



if (( $# != 7)); then
    echo "Usage: $0 uniform|eColiShuffled fromLen toLen step #pairs geneSize patternSize"
    exit -1
else
    model=$1
    start=$2
    last=$3
    step=$4
    numPairs=$5
    geneSize=$6
    patternSize=$7
    if [[ $model == "uniform" ]]; then 
       destDir=$(printf "%s/uniform-%d-%d/len=%d" $prefixPath $patternSize $numPairs $start)
    elif [[ $model == "eColiShuffled" ]]; then
       destDir=$(printf "%s/ecoli-%d-%d-%d/len=%d" $prefixPath $geneSize $patternSize $numPairs $start)
    else
       echo "please specify model = uniform|eColiShuffled"
       exit -1
    fi
fi

spark-submit --class it.unisa.di.bio.DatasetBuilder \
	     --master yarn --deploy-mode client --driver-memory 16g \
	     --num-executors 4 --executor-memory 27g --executor-cores 7 \
	     target/PowerStatistics-1.3-SNAPSHOT-jar-with-dependencies.jar \
	     --output $destDir --generator $model --mode yarn\
             --from-len $start --to-len $last --step $step \
             --pairs $numPairs  --geneSize $geneSize \
             --patternSize $patternSize -f
