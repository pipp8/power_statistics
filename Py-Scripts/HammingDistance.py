#! /usr/local/bin/python

import re
import os
import sys
import random




def hamming_distance(seq1: str, seq2: str) -> int:
    d = sum([ c1 != c2 for c1, c2 in zip(seq1, seq2)])
    return d

def hamming_distance2(seq1: str, seq2: str) -> int:
    return len(list(filter(lambda x : ord(x[0])^ord(x[1]), zip(seq1, seq2))))



# parametri sulla linea di comando
# inputSeqence theta
def CompareSequences():

    (dist, tot1, tot2) = (0, 0, 0)

    if (len(sys.argv) == 3):
        inputFile1 = sys.argv[1]
        inputFile2 = sys.argv[2]
    else:
        print("Errore nei parametri:\nUsage: %s sequence1 sequence2" % os.path.basename(sys.argv[0]))
        exit(-1)

    with open(inputFile1, "r") as inFile1:
        with open(inputFile2, "r") as inFile2:
            # skip all comment lines
            while (True):
                line1 = inFile1.readline()
                if (not line1.startswith(">")):
                    break

            while (True):
                line2 = inFile2.readline()
                if (not line2.startswith(">")):
                    break

            dist += hamming_distance( line1, line2)
            tot1 += len(line1) - 1 # \n
            tot2 += len(line2) - 1 # \n

    print("Hamming distance: %s (%d) vs %s (%d) = %d" % (inputFile1, tot1, inputFile2, tot2, dist))



if __name__ == "__main__":
    CompareSequences()

