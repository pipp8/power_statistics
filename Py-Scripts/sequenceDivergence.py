#! /usr/bin/python3

import re
import os
import sys
import random
import hashlib
from pathlib import Path



basis = ['A', 'C', 'G', 'T']
others = {'A' : ['C', 'G', 'T'], 'C' : ['A', 'G', 'T'], 'G':  ['A', 'C', 'T'], 'T' : ['A', 'C', 'G'] }

ext = '.fna'

# parametri sulla linea di comando
# inputSeqence theta
def ModifySequence(inputFile, outFile, theta):

    if (theta < 0 or theta > 1):
        print(f"theta value: {theta}. theta is a probability and must be 0 <= theta <= 1")
        return -1

    if not os.path.exists(inputFile) or os.path.getsize(inputFile) == 0:
        print(f"input file: {inputFile} does not exist or is void")
        return -1

    if (os.path.exists(outFile)):
        print(f"Output File: {outFile} already exists. Exiting.")
        return -1

    # in caso di link simbolico usa il real filename SOLO per calcolare l'hash
    if os.path.islink(inputFile):
        target = os.readlink(inputFile)
        print(f"{inputFile} is a symbolic link using {target}.")
    else:
        target = inputFile

    # usa solo il filename (con estensione) indipendentemente dalla path
    target = Path(target).name
    # inizializza in maniera replicabili il generatore di numeri casuali
    target_bytes = target.encode("utf-8")
    fnHash = int.from_bytes(hashlib.blake2s(target_bytes, digest_size=4).digest(), "big") 
    seed = int(fnHash * int(theta * 0xA0A0A00))
    
    random.seed(seed)

    print( "*********************************************************")
    print( f"Creating sequence: {Path(outFile).stem} from sequence: {Path(inputFile).stem} theta: {theta}")
    print( f"hash: {fnHash}, seed: {seed:X}")
    print( "*********************************************************")


    sequenceDivergence(inputFile, outFile, theta)



def sequenceDivergence(inputFile, outFile, theta):
    # normalizza theta da 0 <= theta <= 1 a 0 <= theta <= 100
    theta = int(theta * 100)
    (written, subst, totLen) = (0, 0, 0)
    newBase = ''
    out = []
    with open(outFile, "w") as outText:
        with open(inputFile) as inFile:
            for line in inFile:
                if (line.startswith(">")):
                    out = line.rstrip() + ' theta = %d%%\n' % theta
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

                        if (i > 0 and i % 1048576 == 0):
                            written += 1
                            sys.stdout.write('.')
                            sys.stdout.flush()
                            
                    out = "".join(s)
                    totLen += len(line) - 1

                outText.write(out) # \n are in the original strings
                m = totLen // 1048576
                if (m > written):
                    written = m
                    sys.stdout.write('.')
                    sys.stdout.flush()

    print(f"\n{outFile} -> {subst}/{totLen} substitutions")



if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print(f"Errore nei parametri:\nUsage: {os.path.basename(sys.argv[0])} InputSequence thetaProbability")
        exit(-1)
    else:
        inputFile = sys.argv[1]
        theta = float(sys.argv[2])
        baseName, ext = os.path.splitext( inputFile)
        outFile = f"{baseName}-T={theta:05.3f}{ext}"
    
        ModifySequence(inputFile, outFile, theta)
