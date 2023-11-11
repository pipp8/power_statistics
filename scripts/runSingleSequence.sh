#! /bin/bash

if (( $# != 3)); then
    echo "Usage: $0 seq1 seq2  hdfsDataDir"
    # exit -1
    seq1=/home/cattaneo/3rdPartiesSoftware/KMC-3.2.2/tests/ncbi_dataset/data/GCF_000955945.1/GCF_003339765.1_Mmul_10_genomic.fna
    seq2=/home/cattaneo/3rdPartiesSoftware/KMC-3.2.2/tests/ncbi_dataset/data/GCF_000955945.1/GCF_000165445.2_Mmur_3.0_genomic.fna
    dataDir=data
else
    seq1=$1
    seq2=$2
    dataDir=$3
fi


spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	     --num-executors 48 --executor-memory 27g --executor-cores 7 \
	     Py-Scripts/PySparkPASingleSequence.py $seq1 $seq2 $dataDir


