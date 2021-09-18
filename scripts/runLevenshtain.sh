#! /bin/bash


spark-submit --class it.unisa.di.bio.LevenshteinEditDistance \
	     --master yarn --deploy-mode client --driver-memory 16g \
	     --num-executors 4 --executor-memory 27g --executor-cores 7 \
	     target/powerstatistics-1.0-SNAPSHOT.jar \
	     data/test1.fasta yarn


