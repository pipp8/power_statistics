
#! /bin/bash

# SeqLen=1000
# while [ $SeqLen -le 15000 ]; do
#    echo "running for len= $SeqLen"
#    ((SeqLen+=1000))
# done

    
    spark-submit --class it.unisa.di.bio.DatasetBuilder \
		 --master yarn --deploy-mode client --driver-memory 16g \
		 --num-executors 4 --executor-memory 27g --executor-cores 7 \
		 target/powerstatistics-1.0-SNAPSHOT.jar \
		 data/dataset5-1000 detailed yarn 1000000 1000000 100000

