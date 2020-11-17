#! /bin/sh

spark-submit --class it.unisa.di.bio.DatasetBuilder \
  --master yarn --deploy-mode cluster --driver-memory 4g \
  --num-executors 8 --executor-memory 13g --executor-cores 3 \
  target/powerstatistics-1.0-SNAPSHOT.jar \
	/user/cattaneo/data/powerstatistics 10000 100000 5 0.05 ACCCCGT
