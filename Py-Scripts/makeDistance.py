#! /usr/local/bin/python

import re
import os
import sys
import random




basis = ['A', 'C', 'G', 'T']
others = {'A' : ['C', 'G', 'T'], 'C' : ['A', 'G', 'T'], 'G':  ['A', 'C', 'T'], 'T' : ['A', 'C', 'G'] }

# parametri sulla linea di comando
# inputSeqence theta
def ModifySequence():


    if (len(sys.argv) == 3):
        inputFile = sys.argv[1]
        theta = int(sys.argv[2])
    else:
        print("Errore nei parametri:\nUsage: %s InputSequence thetaProbability" % os.path.basename(sys.argv[0]))
        exit(-1)

    outFile = "%s-%d.fasta" % (os.path.splitext( inputFile)[0], theta)
    subst = 0
    totLen = 0
    newBase = ''
    out = []
    with open(outFile, "w") as outText:
        with open(inputFile) as inFile:
            for line in inFile:
                if (line.startswith(">")):
                    out = line.rstrip() + ' theta = %d\n' % theta
                else:
                    s = list(line)
                    for i in range(len(line)):
                        if (random.randrange(100) < theta):
                            # l'elemento i-esimo viene sostituito
                            b = s[i].upper()
                            w = random.randrange(3)
                            if (b == 'A'):
                                newBase = ['C', 'G', 'T'][w]
                            elif (b == 'C'):
                                newBase = ['A', 'G', 'T'][w]
                            elif (b == 'G'):
                                newBase = ['A', 'C', 'T'][w]
                            elif (b == 'T'):
                                newBase = ['A', 'C', 'G'][w]
                            else:
                                # altri caratteri 'N' o fine linea
                                newBase = b

                            # print( "%d: %s->%s" % (i, s[i], newBase), end=" - ")
                            s[i] = newBase
                            subst += 1
                    out = "".join(s)
                    totLen += len(line) - 1

            outText.write(out) # \n are in the original strings


    print("%s -> %d/%d substitutions" % (outFile, subst, totLen))



if __name__ == "__main__":
    ModifySequence()
