#! /usr/bin/python

import re
import os
import sys

inputFile = sys.argv[1]

writeSequenceHistogram = True

seqDistDir = 'seqDists/'

def main():

    if (writeSequenceHistogram):
        if not os.path.exists(seqDistDir):
            os.mkdir(seqDistDir)

    with open(inputFile) as inFile:
        for line in inFile:
            m = re.search(r'^>(.+)\.(\d+)(.*)-([AB]$)', line)
            if (m is None):
                # print line[0:10], "this is a read"
                # save file
                fileName = "%s/%s-%05d%s-%s.fasta" % (seqDistDir, seqName, seqId, gValue, pairId)
                with open(fileName, "w") as outText:
                    outText.write("%s%s" % (hdrLine, line)) # \n are in the original strings

                sys.stdout.write('.')
                sys.stdout.flush()

            else:
                seqName = m.group(1)
                seqId = int(m.group(2))
                gValue = m.group(3)
                pairId = m.group(4)
                hdrLine = line
                # print( "Name: %s, id:%d, GValue: %s, pair:%s" %(seqName, seqId, gValue, pairId))


    print('')



if __name__ == "__main__":
    main()
