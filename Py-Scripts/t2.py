#! /usr/local/bin/python3
import re
import os
import os.path
from pathlib import Path
import sys
import glob
import tempfile
import shutil
import copy
import subprocess
import math
import csv
import time

import numpy as np
import py_kmc_api as kmc

from operator import add
import pyspark
from pyspark.sql import SparkSession
from pyspark import SparkFiles


hdfsPrefixPath = 'hdfs://master2:9000/user/cattaneo'
hdfsDataDir = ''
spark = []
sc = []


def checkPathExists(path: str) -> bool:
    global hdfsDataDir, spark
    # spark is a SparkSession
    sc = spark.sparkContext
    fs = sc._jvm.org.apache.hadoop.fs.FileSystem.get(
        sc._jvm.java.net.URI.create(hdfsDataDir),
        sc._jsc.hadoopConfiguration(),)
    return fs.exists(sc._jvm.org.apache.hadoop.fs.Path(path))




def runCountBasedMeasures(cnts, k):
    D2totValue = 0
    EuclideanTotValue = 0
    for i in range(cnts.shape[1]):
        D2totValue = D2totValue + cnts[0,i] * cnts[1,i]
        d = cnts[0,i] - cnts[1,i]
        EuclideanTotValue = EuclideanTotValue + d * d

    NED = NormalizedSquaredEuclideanDistance( cnts)
    return [int(D2totValue), math.sqrt(EuclideanTotValue), float(NED)]




# we use numpy to not reimplment z-score stndardization from scratch
def NormalizedSquaredEuclideanDistance( vector):
    # (tot1, tot2) = (0, 0)
    # for x in vector:
    #     tot1 += x[0]
    #     tot2 += x[1]
    # n = len(vector)
    # mean1 = tot1 / n
    # mean2 = tot2 / n
    # (totDifferences1,totDifferences2) = (0,0)
    # for v in [((value[0] - mean1)**2, (value[1] - mean2)**2)  for value in vector]:
    #     totDifferences1 += v[0]
    #     totDifferences2 += v[1]
    # standardDeviation1 = (totDifferences1 / n) ** 0.5
    # standardDeviation2 = (totDifferences2 / n) ** 0.5
    # zscores = [((v[0] - mean1) / standardDeviation1, (v[1] - mean2) / standardDeviation2) for v in vector]

    # avg = np.mean( vector, axis=1)
    # std = np.std( vector, axis=1)
    #
    # z0_np = (vector[0] - avg[0]) / std[0]
    # z1_np = (vector[1] - avg[1]) / std[1]
    # tot = 0
    # for i in range(vector.shape[1]):
    #     tot += ((z0_np[i] - z1_np[i]) ** 2)
    #
    # ZEu = tot ** 0.5
    #
    # m = vector.shape[1]
    # D = 2 * m * (1 - (np.dot(vector[0], vector[1]) - m * avg[0] * avg[1]) / (m * std[0] * std[1]))
    var = np.var( vector, axis=1)

    NED = 0.5 * np.var(vector[0] - vector[1]) / (var[0] + var[1])
    return NED




# run jaccard on sequence pair ds with kmer of length = k
def runPresentAbsent(  bothCnt, leftCnt, rightCnt, k):

    A = int(bothCnt)
    B = int(leftCnt)
    C = int(rightCnt)

    NMax = pow(4, k)
    M01M10 = leftCnt + rightCnt
    M01M10M11 = bothCnt + M01M10
    absentCnt = NMax - (A + B + C) # NMax - M01M10M11
    D = absentCnt
    # (M10 + M01) / (M11 + M10 + M01)

    # Anderberg dissimilarity => Anderberg = 1 - (A/(A + B) + A/(A + C) + D/(C + D) + D/(B + D))/4
    try:
        anderberg = 1 - (A/float(A + B) + A/float(A + C) + D/float(C + D) + D/float(B + D))/4.0
    except (ZeroDivisionError, ValueError):
        anderberg = 1.000001

    # Antidice dissimilarity => Antidice = 1 - A/(A + 2(B + C))
    try:
        antidice = 1 - A / float(A + 2.0 * (B + C))
    except (ZeroDivisionError, ValueError):
        antidice = 1.000001

    # Dice dissimilarity => Dice = 1 - 2A/(2A + B + C)
    try:
        dice = 1 - 2*A / float(2.0*A + B + C)
    except (ZeroDivisionError, ValueError):
        dice  = 1.000001
    # Gower dissimilarity => Gower = 1 - A x D/sqrt(A + B) x(A + C) x (D + B x (D + C)
    try:
        gower = 1 - A * D / math.sqrt((A + B) * (A + C) * (D + B * (D + C)))
    except (ZeroDivisionError, ValueError):
        gower = 1.000001

    # Hamman dissimilarity => Hamman = 1 - [((A + D) - (B + C))/N]2
    try:
        hamman = 1 - math.pow((((A + D) - (B + C)) / float(NMax)), 2.0)
    except (ZeroDivisionError, ValueError):
        hamman = 1.000001

    # Hamming dissimilarity => Hamming = (B + C)/N
    try:
        hamming = (B + C)/ NMax
    except (ZeroDivisionError, ValueError):
        hamming = 1.000001

    # Jaccard dissimilarity => Jaccard = 1 - A/(N - D)
    try:
        jaccard = 1 - A / (NMax - D)
    except (ZeroDivisionError, ValueError):
        jaccard = 1.000001

    try:
        jaccardDistance = 1 - min( 1.0, A / float(NMax - D))
    except (ZeroDivisionError, ValueError):
        jaccardDistance = 1.000001


    # Kulczynski dissimilarity => Kulczynski = 1 - (A/(A + B) + A/(A + C)) / 2
    try:
        kulczynski = 1 - (A / float(A + B) + A / float(A + C)) / 2.0
    except (ZeroDivisionError, ValueError):
        kulczynski = 1.000001

    # Matching dissimilarity => Matching = 1 - (A + D)/N
    try:
        matching = 1 - (A + D) / NMax
    except (ZeroDivisionError,ValueError):
        matching = 1.000001

    # Ochiai dissimilarity => Ochiai = 1 - A/sqrt(A + B) x (A + C)
    try:
        ochiai = 1 - A / math.sqrt((A + B) * (A + C))
    except (ZeroDivisionError, ValueError):
        ochiai = 1.000001

    # Phi dissimilarity => Phi = 1 - [(A x  B x  C x D)/sqrt(A + B) x (A + C) x (D + B) x (D + C)]2
    try:
        phi = 1 - math.pow((A * B * C * D)/ math.sqrt((A + B) * (A + C) * (D + B) * (D + C)), 2.0)
    except (ZeroDivisionError, ValueError):
        phi = 1.000001

    # Russel dissimilarity => Russel = 1 - A/N
    try:
        russel = 1 - A / NMax
    except (ZeroDivisionError, ValueError):
        russel = 1.000001

    # Sneath dissimilarity => Sneath = 1 - 2(A + D)/(2 x (A + D) + (B + C))
    try:
        sneath = 1 - 2.0 * (A + D) / (2.0 * (A + D) + (B + C))
    except (ZeroDivisionError, ValueError):
        sneath = 1.000001

    # Tanimoto dissimilarity => Tanimoto = 1 - (A + D)/((A + D) + 2(B + C))
    try:
        tanimoto = 1 - (A + D) / float((A + D) + 2.0 * (B + C))
    except (ZeroDivisionError, ValueError):
        tanimoto = 1.000001

    # Yule dissimilarity => Yule = 1 - [(A x D - B x C)/(A x D + B x C)]2
    try:
        yule = 1 - math.pow(((A * D - B * C) / float(A * D + B * C)), 2.0)
    except (ZeroDivisionError, ValueError):
        yule = 1.000001

    # salva il risultato nel file CSV
    # dati present / absent e distanze present absent
    data1 = [ A, B, C, str(D), str(NMax),
             anderberg, antidice, dice, gower, hamman, hamming, jaccard,
             kulczynski, matching, ochiai, phi, russel, sneath, tanimoto, yule]

    return data1




def runMash(inputDS1, inputDS2, k):
    # run mash on the same sequence pair
    mashValues = []
    for i in range(len(sketchSizes)):
        # extract mash sketch from the first sequence
        cmd = "/usr/local/bin/mash sketch -s %d -k %d %s" % (sketchSizes[i], k, inputDS1)
        p = subprocess.Popen(cmd.split())
        p.wait()

        cmd = "/usr/local/bin/mash sketch -s %d -k %d %s" % (sketchSizes[i], k, inputDS2)
        p = subprocess.Popen(cmd.split())
        p.wait()

        cmd = "/usr/local/bin/mash dist %s.msh %s.msh" % (inputDS1, inputDS2)
        out = subprocess.check_output(cmd.split())

        mashValues.append( MashData( out))

    # dati mash distance
    data2 = []
    for i in range(len(sketchSizes)):
        data2.append( mashValues[i].Pv)
        data2.append( mashValues[i].dist)
        data2.append( mashValues[i].A)
        data2.append( mashValues[i].N)

    # clean up remove kmc temporary files
    os.remove(inputDS1 + '.msh')
    os.remove(inputDS2 + '.msh')

    return data2





def entropyData(entropySeqA, entropySeqB):
    # dati errore entropia e rappresentazione present/absent
    return  [entropySeqA.nKeys, 2 * entropySeqA.totalKmerCnt, entropySeqA.getDelta(), entropySeqA.Hk, entropySeqA.getError(),
             entropySeqB.nKeys, 2 * entropySeqB.totalKmerCnt, entropySeqB.getDelta(), entropySeqB.Hk, entropySeqB.getError()]




# load histogram for both sequences (for counter based measures such as D2)
# and calculate Entropy of the sequence
# dest file è la path sull'HDFS già nel formato hdfs://host:port/xxx/yyy
def loadHistogramOnHDFS2(histFile: str, destFile: str, totKmer: int):

    tmp = histFile + '.txt'

    # dump the result -> kmer histogram (no longer needed)
    cmd = "/usr/local/bin/kmc_dump %s %s" % (histFile, tmp)
    p = subprocess.Popen(cmd.split())
    p.wait()
    # print("cmd: %s returned: %s" % (cmd, p.returncode))

    # trasferisce sull'HDFS il file testuale
    cmd = "hdfs dfs -put %s %s" % (tmp, destFile)
    p = subprocess.Popen(cmd.split())
    p.wait()

    totalDistinct = 0
    totalKmerCnt = 0
    totDistinct = 0
    totalProb = 0.0
    Hk = 0.0

    return (totalDistinct, totalKmerCnt, Hk)








def extractKmers( inputDataset, k, tempDir, kmcOutputPrefix):

    # run kmc on the first sequence
    # -v - verbose mode (shows all parameter settings); default: false
    # -k<len> - k-mer length (k from 1 to 256; default: 25)
    # -m<size> - max amount of RAM in GB (from 1 to 1024); default: 12
    # -sm - use strict memory mode (memory limit from -m<n> switch will not be exceeded)
    # -p<par> - signature length (5, 6, 7, 8, 9, 10, 11); default: 9
    # -f<a/q/m/bam/kmc> - input in FASTA format (-fa), FASTQ format (-fq), multi FASTA (-fm) or BAM (-fbam) or KMC(-fkmc); default: FASTQ
    # -ci<value> - exclude k-mers occurring less than <value> times (default: 2)
    # -cs<value> - maximal value of a counter (default: 255)
    # -cx<value> - exclude k-mers occurring more of than <value> times (default: 1e9)
    # -b - turn off transformation of k-mers into canonical form
    # -r - turn on RAM-only mode
    # -n<value> - number of bins
    # -t<value> - total number of threads (default: no. of CPU cores)
    # -sf<value> - number of FASTQ reading threads
    # -sp<value> - number of splitting threads
    # -sr<value> - number of threads for 2nd stage
    # -hp - hide percentage progress (default: false)

    cmd = "/usr/local/bin/kmc -b -hp -k%d -m2 -fm -ci0 -cs1048575000 -cx2000000000 %s %s %s" % (k, inputDataset, kmcOutputPrefix, tempDir)
    out = subprocess.check_output(cmd.split())

    m = re.search(r'Total no. of k-mers[ \t]*:[ \t]*(\d+)', out.decode())
    totalKmerNumber = 0 if (m is None) else int(m.group(1))
    # print("cmd: %s returned:\n%s" % (cmd, out))
                            
    # p = subprocess.Popen(cmd.split())
    # p.wait()
    # print("cmd: %s returned: %s" % (cmd, p.returncode))

    # dump the result -> kmer histogram (no longer needed)
    #cmd = "/usr/local/bin/kmc_dump %s %s" % ( kmcOutputPrefix, histFile)
    # p = subprocess.Popen(cmd.split())
    # p.wait()
    # print("cmd: %s returned: %s" % (cmd, p.returncode))

    return totalKmerNumber




def splitAndCount(cnt, x: str):
    cnt += 1
    return x.split('\t')[0]



def distCounter(cnt, x: str):
    cnt += 1
    return x




# run jaccard on sequence pair ds with kmer of length = k
def processLocalPair2(seqFile1: str, seqFile2: str):

    k = 24
    start = time.time()
    print(f"program started @{start}")

    tot1Acc = sc.accumulator(0)
    seq1 = sc.textFile(seqFile1).map( lambda x: splitAndCount( tot1Acc, x))
    
    tot2Acc = sc.accumulator(0)
    seq2 = sc.textFile(seqFile2).map( lambda x: splitAndCount( tot2Acc, x))
    
    intersection = seq1.intersection(seq2)

    outputFile = '%s/k=%d-%s-%s.txt' % (hdfsDataDir, k, Path(seqFile1).stem, Path(seqFile2).stem)

    tot3Acc = sc.accumulator(0)
    intersection.map(lambda x: distCounter(tot3Acc, x)).saveAsTextFile( outputFile)    
    bothCnt = tot3Acc.value
    leftCnt = tot1Acc.value - bothCnt
    rightCnt = tot2Acc.value - bothCnt

    end = time.time()
    print(f"tempo reale: end @{end:.03f} {(end-start)*10**3:.03f} ms")
    print("********* k: %d, A: %d, B: %d, C: %d ***********" % (k, bothCnt, leftCnt, rightCnt))
          

    return
                 






def main():
    global hdfsDataDir, hdfsPrefixPath, spark, sc

    hdfsDataDir = hdfsPrefixPath

    argNum = len(sys.argv)
    if (argNum < 3 or argNum > 4):
        """
            Usage: PySparkPAbSingleSequence Sequence1 Sequence2 [dataDir]
        """
    elif argNum == 4:
        hdfsDataDir = '%s/%s' % (hdfsPrefixPath, sys.argv[3])

    seqFile1 = "%s/%s" % (hdfsDataDir, sys.argv[1]) # le sequenze sono gia' sull'HDFS nel formato kmc_dump.txt
    seqFile2 = "%s/%s" % (hdfsDataDir, sys.argv[2]) # per eseguire localmente l'estrazione dei k-mers
    # outFile = '%s/%s-%s.csv' % (hdfsDataDir, Path( seqFile1).stem, Path(seqFile2).stem )

    print("hdfsDataDir = %s" % hdfsDataDir)
    
    spark = SparkSession \
        .builder \
        .appName("%s %s %s" % (Path( sys.argv[0]).stem, Path(seqFile1).stem, Path(seqFile2).stem)) \
        .getOrCreate()

    sc = spark.sparkContext

    sc2 = spark._jsc.sc()
    nWorkers =  len([executor.host() for executor in sc2.statusTracker().getExecutorInfos()]) -1

    if (not checkPathExists( hdfsDataDir)):
        print("Data dir: %s does not exist. Program terminated." % hdfsDataDir)
        exit( -1)

    print("%d workers, hdfsDataDir: %s" % (nWorkers, hdfsDataDir))

    processLocalPair2(seqFile1, seqFile2)

    spark.stop()





    
if __name__ == "__main__":
    main()
