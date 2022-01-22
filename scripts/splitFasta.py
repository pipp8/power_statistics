#! /usr/bin/python

import re
import os
import sys

writeSequenceHistogram = True
seqDistDir = 'seqDists'



def main():

    splitFastaSequences(sys.argv[1])

    
    
def splitFastaSequences( inputFile):

    if (writeSequenceHistogram):
        if not os.path.exists(seqDistDir):
            os.mkdir(seqDistDir)

    m = re.search(r'^(.*)-(\d+)\.(\d+)(.*).fasta', inputFile)
    if (m is None):
        print("Malformed file name %s" % inputFile)
        exit(-1)
    else:
        seqName = m.group(1)
        pairsNumber = int(m.group(2))
        pairsLen = int(m.group(3))
        gValue = m.group(4)

    with open(inputFile) as inFile:
        for line in inFile:
            m = re.search(r'^>(.+)\.(\d+)(.*)-([AB]$)', line)
            if (m is None):
                # save file
                fileName = "%s/%s-%04d.%d%s-%s.fasta" % (seqDistDir, seqName, seqId, pairsLen, gValue, pairId)
                with open(fileName, "w") as outText:
                    outText.write("%s%s" % (hdrLine, line)) # \n are in the original strings

                sys.stdout.write('.')
                sys.stdout.flush()

            else:
                # seqName = m.group(1)
                seqId = int(m.group(2))
                # gValue = m.group(3)
                pairId = m.group(4)
                hdrLine = line
                # print( "Name: %s, id:%d, GValue: %s, pair:%s" %(seqName, seqId, gValue, pairId))


    print('')



if __name__ == "__main__":
    main()
