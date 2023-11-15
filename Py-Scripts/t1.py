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

import numpy as np
import py_kmc_api as kmc
import time

from operator import add
import pyspark
from pyspark.sql import SparkSession
from pyspark import SparkFiles


hdfsPrefixPath = 'hdfs://master2:9000/user/cattaneo'
hdfsDataDir = ''
spark = []
sc = []

nTests = 1000
minK = 4
maxK = 32
stepK = 4
# sketchSizes = [1000, 10000, 100000]
sketchSizes = [ 10000]
outFilePrefix = 'PresentAbsentECData'





# load histogram for both sequences (for counter based measures such as D2)
# and calculate Entropy of the sequence
# dest file è la path sull'HDFS già nel formato hdfs://host:port/xxx/yyy
def KMCLocalDump(histFile: str, destFile: str):
    (totalKmerCnt, totDistinct) = (0, 0)

    kmcFile = kmc.KMCFile()
    if (not kmcFile.OpenForListing(histFile)):
        raise IOError( "OpenForListing failed for %s DB." % histFile)

    info = kmcFile.Info()
    k = kmcFile.KmerLength()
    totalDistinct = kmcFile.KmerCount()

    print("KMC db file: %s opened, k = %d, totalDistinct = %d" % (histFile, k, totalDistinct))

    kmer = kmc.KmerAPI(k)
    cnt  = kmc.Count()

    # histFile contiene il DB con l'istogramma di una sola sequenza prodotto con kmc 3
    kmcFile.RestartListing()
    with open(destFile, 'w') as writer:
        while(kmcFile.ReadNextKmer( kmer, cnt)):
            strKmer = kmer.__str__()
            count = cnt.value
            totalKmerCnt += count
            totDistinct += 1
            
            # write on HDFS the kmer with its counter
            writer.write('%s\t%d\n' % (strKmer, count))
            # print('%s, %d' % (strKmer, count))

    print("totKmerCnt = %d, totDistinct = %d" % (totalKmerCnt, totDistinct))
    kmcFile.Close()

    return




# load histogram for both sequences (for counter based measures such as D2)
# and calculate Entropy of the sequence
# dest file è la path sull'HDFS già nel formato hdfs://host:port/xxx/yyy
def loadHistogramOnHDFS(histFile: str, destFile: str):
    (totalKmerCnt, totDistinct) = (0, 0)
    kmcFile = kmc.KMCFile()
    if (not kmcFile.OpenForListing(histFile)):
        raise IOError( "OpenForListing failed for %s DB." % histFile)

    info = kmcFile.Info()
    k = kmcFile.KmerLength()
    totalDistinct = kmcFile.KmerCount()

    print("KMC db file: %s opened, k = %d, totalDistinct = %d" % (histFile, k, totalDistinct))

    kmer = kmc.KmerAPI(k)
    cnt  = kmc.Count()

    totalKmerCnt = 0
    totDistinct = 0
    totalProb = 0.0
    Hk = 0.0

    URI = sc._gateway.jvm.java.net.URI
    Path = sc._gateway.jvm.org.apache.hadoop.fs.Path
    FileSystem = sc._gateway.jvm.org.apache.hadoop.fs.FileSystem
    conf = sc._jsc.hadoopConfiguration()
    fs = Path(destFile).getFileSystem(sc._jsc.hadoopConfiguration())
    ostream = fs.create(Path(destFile))
    writer = sc._gateway.jvm.java.io.BufferedWriter(sc._jvm.java.io.OutputStreamWriter(ostream))
    print("HDFS Writer: %s opened" % destFile)

    # histFile contiene il DB con l'istogramma di una sola sequenza prodotto con kmc 3
    kmcFile.RestartListing()
    while(kmcFile.ReadNextKmer( kmer, cnt)):
        strKmer = kmer.__str__()
        count = cnt.value
        totalKmerCnt += count
        totDistinct += 1

        # write on HDFS the kmer with its counter
        writer.write('%s\t%d\n' % (strKmer, count))
        # print('%s, %d' % (strKmer, count))


    writer.close()
    print("totKmerCnt = %d, totDistinct = %d" % (totalKmerCnt, totDistinct))
    
    return 









def main():
    global hdfsDataDir, hdfsPrefixPath, spark, sc

    hdfsDataDir = hdfsPrefixPath

    seqFile1 = sys.argv[1] # le sequenze sono sul file system locale

    print(f"hdfsDataDir = {hdfsDataDir}")
    
    spark = SparkSession \
        .builder \
        .appName("%s %s" % (Path( sys.argv[0]).stem, Path(seqFile1).stem)) \
        .getOrCreate()

    sc = spark.sparkContext

    start = time.time()
    print(f"program started @{start}")

    KMCLocalDump(seqFile1, Path( seqFile1).stem + ".txt")

    end = time.time()
    print(f"tempo reale: end @{end} {(end-start)*10**3:.03f}ms")

    start = time.time()
    print(f"program started @{start}")

    destFile = hdfsDataDir + "/data/" + Path( seqFile1).stem + ".txt"

    loadHistogramOnHDFS(seqFile1, destFile)

    end = time.time()
    print(f"tempo reale: end @{end} {(end-start)*10**3:.03f}ms")
    
    spark.stop()




if __name__ == "__main__":
    main()
