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
defDataDir = '/mnt/VolumeDati1/Dataset/PresentAbsentDatasets/ncbi_dataset/taxonomy-20260829'
remoteDataDir = 'taxonomy-20260829'

refSeq = 'HomoSapiens.fna'
seqs = [ 'Gorilla.fna']

# seqs = [
#    'Bonobo.fna',      'Gallus.fna',   'GrayMouseLemur.fna',  'HouseMouse.fna',
#    'MacacaMulatta.fna',   'Orangutan.fna',  'SootyMangabey.fna', 'Chimpanzee.fna',
#    'Gorilla.fna',     'MacacaMulatta.fna',  'Pig.fna']




def main():
    global refSeq, seqs
    
    parser = argparse.ArgumentParser(description='Script per il calcolo delle distanze di refSeq con tutte le sequenze in seqs')
    parser.add_argument('-d', '--datadir', default=defDataDir, type=str, help='Path completa della directory contenente i file FASTA da confrontare')
    parser.add_argument('-v', '--dry', action='store_true', help='Disabilita l\'esecuzione mostrando solo i test da effettuare (default=false)')
    parser.add_argument('-p', '--pattern', action='store_true', help='Global pattern to select input files')
    
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

    if args.pattern:
        seqs = glob.glob(args.pattern)
        print(f"Using the following sequences: {seqs}")

    os.chdir(cwd)
    
    cnt = 0
    tot = len(seqs)


    for p in seqs:
 
        seq1 = f"{args.datadir}/{refSeq}"
        seq2 = f"{args.datadir}/{p}"

        cnt += 1
        logger.info(f"Running test {cnt}/{tot}: {seq1} vs {seq2}")
        # theta = 0 (no synthetic sequences)
        # tutti i k con 4 <= k <= 32
        cmd = f"spark-submit --master yarn --deploy-mode client --driver-memory 27g \
	        --num-executors 48 --executor-memory 27g --executor-cores 7 \
	        {scriptPath} {seq1} {seq2} -r {remoteDataDir}"

        
        if (not dryMode):
            logger.info(f"Executing {cmd}")
            out_f = open(logFile, 'w')
            subprocess.run( cmd.split(), stdout = out_f, text = True, stderr = subprocess.STDOUT)
            logger.info("Done.")







if __name__ == "__main__":
    main()




