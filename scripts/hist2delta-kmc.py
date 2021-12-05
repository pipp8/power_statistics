#! /usr/bin/python

import re
import os
import sys
import math
import csv


inputFile = sys.argv[1]

totalCnt = 0
totalSeqCnt = 0
totalKmer = 0
totalProb = 0.0
totalLines = 0

sumDict = dict()  # dizionario vuoto
dist = 'dist' # directory per le distribuzioni
basename = os.path.splitext(os.path.basename(inputFile))[0]
outFile = 'PAResults.csv'

def main():
    global totalCnt, totalSeqCnt, totalKmer, totalProb, totalLines, sumDict, seqDict
    k = 0
    model = ''
    pairId = 1
    seqLen = 0
    gamma = 0.0
    seqId = '-'
    m = re.search(r'^.*k=(\d+)_(.*)-(\d+)\.(\d+)(.*)-([AB])', basename)
    if (m is not None):
        k = int(m.group(1))
        model = m.group(2)
        pairId = int(m.group(3))
        seqLen = int(m.group(4))
        gamma = float("0."+m.group(5)[3:])
        seqId = m.group(6)
        print("Processing histogram: %s k=%d, model=%s, pair=%d, len=%d, gamma=%.2f, S=%s" %
              (basename, k, model, pairId, seqLen, gamma, seqId))
    else:
        print("did not match")

    # ogni file contiene l'istogramma di una sola sequenza prodotto con kmc 3
    with open(inputFile) as inFile:
        seqDict = dict()
        totalSeqCnt = 0
        seqNum = 1
        for line in inFile:
            # m = re.search(r'^([A-Z]+)[ \t]+(\d+)', line)
            # if (m is None):
            #    print line, " malformed histogram file"
            #    exit()
            # else:
            #    kmer = m.group(1)
            #    count = int(m.group(2))
            s = line.split()   # molto piu' veloce della re
            if (len(s) != 2):
                print( "%sMalformed histogram file (%d token)" % (line, len(s)))
                exit()
            else:
                kmer = s[0]
                count = int(s[1])

            # totale generale per il calcolo della probabilita' empirica
            totalCnt = totalCnt + count
            totalSeqCnt = totalSeqCnt + count
            totalLines = totalLines + 1

            if kmer in sumDict:
                sumDict[kmer] = sumDict[kmer] + int(count)
            else:
                sumDict[kmer] = int(count)


    totalKmer = 0
    totalProb = 0
    #probFile = "%s/%s.dist" % (dist, basename)
    # with open(probFile, "w") as outDist :
    #    kmers = sorted(sumDict.keys())
    Hk = 0.0
    for key in sumDict.keys():
        prob = sumDict[key] / float(totalCnt)
        totalProb = totalProb + prob
        totalKmer = totalKmer + 1
        Hk = Hk + prob * math.log(prob, 2)
        # print( "prob(%s) = %f log(prob) = %f" % (key, prob, math.log(prob, 2)))

    Hk = Hk * -1
    Nmax = len(sumDict.keys())
    if (totalKmer != Nmax):
        print( "errore %d vs %d" % (totalKmer, Nmax))
        exit(-1)

    if (round(totalProb,0) != 1.0):
        print( "errore Somma(p) = %f" % (totalProb))
        exit(-1)

    # print("total kmer values:\t%d" % totalLines)  # numero dei conteggi
    print("total distinct kmers (Nmax):\t%d" % totalKmer)# Nmax number of distinct kmers with frequency > 0
    print("total kmers counter:\t%d" % totalCnt)  # totale conteggio
    # print("total prob-distr.:\t%f" % totalProb)  # totale distribuzione di probabilita'
    N = totalCnt
    delta = float(Nmax) / (2 * N)
    header = ['Model', 'G', 'len', 'pairdId', 'k', 'Nmax', '2N', 'delta', 'Hk', 'error']
    data = [model, gamma, seqLen, pairId, k, Nmax, 2*N, delta, Hk, delta/Hk ]

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


if __name__ == "__main__":
    main()
