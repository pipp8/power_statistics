#! /bin/bash


spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	     --num-executors 48 --executor-memory 27g --executor-cores 7 \
	     PySparkPresentAbsent4.py 10000 8-32


