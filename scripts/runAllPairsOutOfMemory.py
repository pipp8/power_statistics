#! /usr/bin/python3

import os
import sys
import glob
import itertools
import subprocess
import time
import math
import argparse
import logging


scriptPath = '/home/cattaneo/spark/power_statistics/Py-Scripts/PyPASingleSequenceOutMemory.py'
# dataDir='/home/cattaneo/spark/power_statistics/Dataset'
defDataDir = '/mnt/VolumeDati1/Dataset/PresentAbsentDatasets/ncbi_dataset/taxonomy'
remoteDataDir = 'taxonomy'


seqs = [
    'GCA_000001405.29_GRCh38.p14_genomic.fna',
    'GCA_000001515.5_Pan_tro_3.0_genomic.fna',
    'GCA_000151905.3_gorGor4_genomic.fna',
    'GCA_028885655.3_NHGRI_mPonAbe1-v2.1_pri_genomic.fna',
    'GCA_029289425.3_NHGRI_mPanPan1-v2.1_pri_genomic.fna',
    'GCF_000001635.27_GRCm39_genomic.fna',
    'GCF_016699485.2_bGalGal1.mat.broiler.GRCg7b_genomic.fna'
]



def main():

    parser = argparse.ArgumentParser(description='Script per l\'esecuzione di tutte le coppie')
    parser.add_argument('-d', '--datadir', default=defDataDir, type=str, help='Path completa della directory contenente i file FASTA da confrontare')
    parser.add_argument('-v', '--dry', action='store_true', help='Disabilita l\'esecuzione mostrando solo i test da effettuare (default=false)')
    parser.add_argument('-p', '--pattern', default='GC*.fna', action='store_true', help='Global pattern to select input files')
    
    args = parser.parse_args()

    dryMode = args.dry

    # Configurazione logger
    logFile = f"MainRun-{int(time.time())}.log"
    logging.basicConfig(
        level=logging.DEBUG,
        format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        handlers=[
            logging.FileHandler(logFile),
            logging.StreamHandler()  # anche su console
        ]
    )
    logger = logging.getLogger('genomica')
    
    if dryMode:
        logger.info("Runnning in dry mode. Tests will not be executed.\n")

    if (not os.path.isdir(args.datadir)):
        logger.error(f"Local data directory '{args.datadir}' does not exists. Exiting.")
        exit(-1)

    cwd = os.getcwd()
    os.chdir(args.datadir)
    seq = glob.glob(args.pattern)

    os.chdir(cwd)
    
    cnt = 0
    tot = math.comb(len(seqs), 2)
    # testList = list(itertools.combinations( seqs, 2))
    testList = itertools.combinations( seqs, 2)

    for p in testList:
 
        seq1 = f"{args.datadir}/{p[0]}"
        seq2 = f"{args.datadir}/{p[1]}"

        cnt += 1
        logger.info(f"Running test {cnt}/{tot}: {p[0]} vs {p[1]}")
        # theta = 0 (no synthetic sequences)
        # tutti i k con 4 <= k <= 32
        cmd = f"spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	        --num-executors 48 --executor-memory 27g --executor-cores 7 \
	        {scriptPath} {seq1} {seq2} -r {remoteDataDir}"

        
        if (not dryMode):
            out_f = open(logFile, 'w')
            subprocess.run( cmd.split(), stdout = out_f, text = True, stderr = subprocess.STDOUT)
            logger.info("Done.")







if __name__ == "__main__":
    main()




