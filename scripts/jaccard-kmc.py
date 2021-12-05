#! /usr/bin/python

import re
import os
import sys
import glob
import subprocess
import csv
import numpy as np




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



def main():
    outFile = 'JaccardData.csv'
    k = int(sys.argv[1])
    ds = sys.argv[2]
    datasetA = ds + 'A.fasta'
    datasetB = ds + 'B.fasta'
    tempDir = "tmp.%d" % os.getpid()
    os.mkdir(tempDir)

    m = re.search(r'^(.*)-(\d+)\.(\d+)(.*)-', ds)
    if (m is not None):
        model = m.group(1)
        pairId = int(m.group(2))
        seqLen = int(m.group(3))
        gamma = float("0."+m.group(4)[3:])
    else:
        print('Malformed dataset name')

    kmcOutputPrefixA = "k=%d%s-A" % (k, ds)
# run kmc on the first sequence
    cmd = "kmc -b -k%d -m2 -fm -ci0 -cs1000000 %s %s %s" % (k, datasetA, kmcOutputPrefixA, tempDir)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    # dump the result -> kmer histogram
    histFileA = "distk=%d_%sA.hist" % (k, ds)
    cmd = "kmc_dump %s %s" % ( kmcOutputPrefixA, histFileA)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    # run kmc on the second sequence
    kmcOutputPrefixB = "k=%d%s-B" % (k, ds)
    cmd = "kmc -b -k%d -m2 -fm -ci0 -cs1000000 %s %s %s" % (k, datasetB, kmcOutputPrefixB, tempDir)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    # dump the result -> kmer histogram
    histFileB = "distk=%d_%sB.hist" % (k, ds)
    cmd = "kmc_dump %s %s" % ( kmcOutputPrefixB, histFileB)
    p = subprocess.Popen(cmd.split())
    p.wait()
    print("cmd: %s returned: %s" % (cmd, p.returncode))

    leftKmers = loadKmerList(histFileA)
    rightKmers = loadKmerList(histFileB)

    print("left: %d, right: %d" % (leftKmers.size, rightKmers.size))

    intersection = np.intersect1d( leftKmers, rightKmers)
    bothCnt = intersection.size
    leftCnt = leftKmers.size - bothCnt
    rightCnt = rightKmers.size - bothCnt

    NMax = pow(4, k)
    absentCnt = NMax - (bothCnt + leftCnt + rightCnt)

    header = ['model', 'gamma', 'seqLen', 'pairId', 'k', 'Both', 'leftOnly', 'rightOnly', 'absent', 'Nmax']
    data = [model, gamma, seqLen, pairId, k, bothCnt, leftCnt, rightCnt, absentCnt, NMax]

    if (not os.path.exists( outFile)):
        f = open(outFile, 'w')
        writer = csv.writer(f)
        writer.writerow(header)
    else:
        f = open(outFile, 'a')
        writer = csv.writer(f)

    writer.writerow(data)
    f.close()
    print( data)
    # cleanup
    os.rmdir(tempDir)
    os.remove(histFileA)
    os.remove(histFileB)
    for f in glob.glob(kmcOutputPrefixA+'*'):
        os.remove(f)
    for f in glob.glob(kmcOutputPrefixB+'*'):
        os.remove(f)

if __name__ == "__main__":
    main()
