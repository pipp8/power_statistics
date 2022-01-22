#! /usr/bin/python

import re
import os
import sys
import glob
import subprocess
import csv
from filelock import Timeout, FileLock
import numpy as np

libPath = '/home/cattaneo/spark/power_statistics/scripts'
if (os.path.exists(libPath)):
    sys.path.append(libPath)
    import splitFasta

    
# process private temporary directory
tempDir = "tmp.%d" % os.getpid()

models = ['Uniform', 'MotifRepl-U', 'PatTransf-U', 'Uniform-T1']
lengths = [2000, 20000, 200000, 2000000, 20000000]
lengths = [2000, 20000]
gVals = [10, 50, 100]
nPairs = 1000
nTests = 3
minK = 4
maxK = 12
outFile = 'PresentAbsentData.csv'
hdfsDataDir = 'data/dataset7-1000'


def extractKmers( dataset, k, seq):
    inputDataset = '%s/%s-%s.fasta' % (splitFasta.seqDistDir, dataset, seq)
    kmcOutputPrefix = "%s/k=%d%s-%s" % (tempDir, k, dataset, seq)
    # run kmc on the first sequence
    cmd = "kmc -b -k%d -m2 -fm -ci0 -cs1000000 %s %s %s" % (k, inputDataset, kmcOutputPrefix, tempDir)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    # dump the result -> kmer histogram
    histFile = "%s/distk=%d_%s-%s.hist" % (tempDir, k, dataset,seq)
    cmd = "kmc_dump %s %s" % ( kmcOutputPrefix, histFile)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))
    # load kmers from histogram file
    vect = loadKmerList(histFile)
    # remove temporary files
    # os.remove(histFile)
    # for f in glob.glob(kmcOutputPrefix+'*'):
    #    os.remove(f)
    return vect


def loadKmerList( file):
    print("Loading from file %s" % file)
    # ogni file contiene l'istogramma di una sola sequenza prodotto con kmc 3
    with open(file) as inFile:
        seqDict = dict()
        for line in inFile:
            s = line.split()   # molto piu' veloce della re
            if (len(s) != 2):
                print( "%sMalformed histogram file (%d token)" % (line, len(s)))
                exit()
            else:
                kmer = s[0]
                count = int(s[1])

            if kmer in seqDict:
                seqDict[kmer] = seqDict[kmer] + count
            else:
                seqDict[kmer] = count

    return np.array(seqDict.keys())



# run jaccard on sequence pair ds with kmer of length = k
def runPresentAbsent( ds, k):

    print( ds)
    m = re.search(r'^(.*)-(\d+)\.(\d+)(.*)', ds)
    if (m is not None):
        model = m.group(1)
        pairId = int(m.group(2))
        seqLen = int(m.group(3))
        gamma = float('0.' + m.group(4)[5:])
    else:
        print('Malformed dataset name')


    leftKmers = extractKmers(ds, k, 'A')
    rightKmers = extractKmers(ds, k, 'B')

    print("left: %d, right: %d" % (leftKmers.size, rightKmers.size))

    intersection = np.intersect1d( leftKmers, rightKmers)
    bothCnt = intersection.size
    A = bothCnt
    leftCnt = leftKmers.size - bothCnt
    B = leftCnt
    rightCnt = rightKmers.size - bothCnt
    C = rightCnt
    
    NMax = pow(4, k)
    M01M10 = leftCnt + rightCnt
    M01M10M11 = bothCnt + M01M10
    absentCnt = NMax - (A + B + C) # M01M10M11
    D = absentCnt
    # (M10 + M01) / (M11 + M10 + M01)
    # jaccardDistance = M01M10 / float(M01M10M11)
    jaccardDistance = 1 - min( 1.0, A / float(NMax - D))
    
    header = ['model', 'gamma', 'seqLen', 'pairId', 'k', 'Jaccard Distance', 'A', 'B', 'C', 'D', 'Nmax']
    data = [model, gamma, seqLen, pairId, k, jaccardDistance, bothCnt, leftCnt, rightCnt, absentCnt, NMax]

    lock = FileLock(outFile + '.lck')
    try:
        lock.acquire(5)
        print("Lock acquired.")
        print( data)
        if (not os.path.exists( outFile)):
            f = open(outFile, 'w')
            writer = csv.writer(f)
            writer.writerow(header)
        else:
            f = open(outFile, 'a')
            writer = csv.writer(f)

        writer.writerow(data)
        f.close()
        lock.release()

    except Timeout:
        print("Another instance of this application currently holds the lock.")




def main():

    # process private temporary directory
    os.mkdir(tempDir)

    for seqLen in lengths:
        for model in models:
            gammas = [ ' ' ]  if model.startswith('Uniform') else gVals        
            for g in gammas:
                # PatTransf-U-1000.9600000.G=0.100.fasta oppure Uniform-1000.1000000.fasta
                gamma = '' if g == ' ' else '.G=0.%03d' % g
                dataset = '%s-%d.%d%s.fasta' % (model, nPairs, seqLen, gamma)
                
                # download from hdfs the dataset
                cmd = "hdfs dfs -get %s/%s ." % (hdfsDataDir, dataset) 
                p = subprocess.Popen(cmd.split())
                p.wait()
                print("cmd: %s returned: %s" % (cmd, p.returncode))
                
                splitFasta.splitFastaSequences( dataset)
            
                for seqId in range(1, nTests):
                    
                    ds = '%s-%04d.%d%s' % (model, seqId, seqLen, gamma)
                    for k in range(4, 32, 4):
                        
                        # run kmc on both the sequences and eval A, B, C, D
                        runPresentAbsent(ds, k)
                                            
                        # calcola Mash
                        
                        # calcola Hk
                        



                        

if __name__ == "__main__":
    main()
