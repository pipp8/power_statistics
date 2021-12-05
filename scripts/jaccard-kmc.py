#! /usr/bin/python

import re
import os
import sys
import glob
import subprocess
import csv
from filelock import Timeout, FileLock
import numpy as np

# private temporary directory
tempDir = "tmp.%d" % os.getpid()
os.mkdir(tempDir)


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


def extractKmers( dataset, k, seq):
    inputDataset = '%s-%s.fasta' % (dataset, seq)
    kmcOutputPrefix = "k=%d%s-%s" % (k, dataset, seq)
    # run kmc on the first sequence
    cmd = "kmc -b -k%d -m2 -fm -ci0 -cs1000000 %s %s %s" % (k, inputDataset, kmcOutputPrefix, tempDir)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    # dump the result -> kmer histogram
    histFile = "distk=%d_%s-%s.hist" % (k, dataset,seq)
    cmd = "kmc_dump %s %s" % ( kmcOutputPrefix, histFile)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))
    # load kmers from histogram file
    vect = loadKmerList(histFile)
    # remove temporary files
    os.remove(histFile)
    for f in glob.glob(kmcOutputPrefix+'*'):
        os.remove(f)

    return vect

gVals = [ 10, 50, 100]
lengths = [2000, 20000, 200000, 2000000, 20000000]
minK = 4
maxK = 62

def main():
    l = len(sys.argv)
    if (l <= 1 || l >= 3):
        print("Errore nei parametri:")
        print("Usage: %s model [k]" % sys.argv[0])
        exit(-1)

    if (l > 1):
        model = sys.argv[1]

    if (l > 2):
        minK = int(sys.argv[2])
        maxK = minK

    gammas =  ['none'] if model.startswith('Uniform') else gVals
    for seqLen in lengths:
        for seqId in range(1, 21):
            if (not gammas):
                for g in gammas:
                    gamma = '' if g == 'none' else '.G=%03d' % g
                    k = minK
                    while (k <= maxK):
                        dataset = '%s-%04d.%d%s' % (model, seqId, seqLen, gamma)
                        runJaccard( dataset, k)

                        if (k < 20):
                            k += 2
                        elif (k < 30):
                            k += 3
                        else:
                            k += 10



# run jaccard on sequence pair ds with kmer of length = k
def runJaccard( ds, k):

    outFile = 'JaccardData.csv'
    m = re.search(r'^(.*)-(\d+)\.(\d+)(.*)-', ds)
    if (m is not None):
        model = m.group(1)
        pairId = int(m.group(2))
        seqLen = int(m.group(3))
        gamma = float("0."+m.group(4)[3:])
    else:
        print('Malformed dataset name')


    leftKmers = extractKmers(ds, k, 'A')
    rightKmers = extractKmers(ds, k, 'B')

    print("left: %d, right: %d" % (leftKmers.size, rightKmers.size))

    intersection = np.intersect1d( leftKmers, rightKmers)
    bothCnt = intersection.size
    leftCnt = leftKmers.size - bothCnt
    rightCnt = rightKmers.size - bothCnt

    NMax = pow(4, k)
    absentCnt = NMax - (bothCnt + leftCnt + rightCnt)

    header = ['model', 'gamma', 'seqLen', 'pairId', 'k', 'Both', 'leftOnly', 'rightOnly', 'absent', 'Nmax']
    data = [model, gamma, seqLen, pairId, k, bothCnt, leftCnt, rightCnt, absentCnt, NMax]

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

    # cleanup
    os.rmdir(tempDir)



if __name__ == "__main__":
    main()