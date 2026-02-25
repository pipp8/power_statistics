#! /usr/bin/python3

import sys
import itertools
import subprocess
import time
import math


scriptPath = '/home/cattaneo/spark/power_statistics/Py-Scripts/PyPASingleSequenceOutMemory.py'
# dataDir='/home/cattaneo/spark/power_statistics/Dataset'
dataDir = '/mnt/VolumeDati1/Dataset/PresentAbsentDatasets/ncbi_dataset/taxonomy'
remoteDataDir = 'taxonomy'


seqs = [
    'GCA_000001405.29_GRCh38.p14_genomic.fna',
    'GCA_000001515.5_Pan_tro_3.0_genomic.fna',
    'GCA_000151905.3_gorGor4_genomic.fna',
    'GCA_028885655.3_NHGRI_mPonAbe1-v2.1_pri_genomic.fna',
    'GCA_029289425.3_NHGRI_mPanPan1-v2.1_pri_genomic.fna',
    'GCF_000001635.27_GRCm39_genomic.fna'
    'GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b_genomic.fna'
]



def main():

    dryMode = "--dry" in sys.argv

    if dryMode:
        print("Runnning in dry mode. Tests will not be executed.\n")

    cnt = 0
    tot = math.comb(len(seqs), 2)
    testList = itertools.combinations( seqs, 2)
    for p in testList:
 
        seq1 = f"{dataDir}/{p[0]}"
        seq2 = f"{dataDir}/{p[1]}"

        cnt += 1
        print(f"Running test {cnt}/{tot}: {p[0]} vs {p[1]}")
        
        cmd = f"spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	--num-executors 48 --executor-memory 27g --executor-cores 7 \
	{scriptPath} {seq1} {seq2} 0 {remoteDataDir}"

        logFile = f"run-{int(time.time())}.log"

        if (not dryMode):
            out_f = open(logFile, 'w')
            subprocess.run( cmd.split(), stdout = out_f, text = True, stderr = subprocess.STDOUT)






if __name__ == "__main__":
    main()




