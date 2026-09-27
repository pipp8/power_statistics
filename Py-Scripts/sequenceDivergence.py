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
def ModifySequence(inputFile, outFile, theta, verbose=False):

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


    sequenceDivergence(inputFile, outFile, theta, verbose)



def sequenceDivergence(inputFile, outFile, theta, verbose=False):
    
    # normalizza theta da 0 <= theta <= 1 a 0 <= theta <= 100
    theta = int(theta * 100)
    mb = 2**20 # megabyte
    totalSize = f"{os.path.getsize(inputFile) / mb:.3f}"
    (written, subst, totLen) = (-1, 0, 0)
    newBase = ''
    headerLine = True
    out = []
    with open(outFile, "w") as outText:
        with open(inputFile) as inFile:
            for line in inFile:
                if (line.startswith(">"):
                    # si tratta di un commento
                    if (headerLine):
                        out = line.rstrip() + f" theta = {theta}%\n"
                        # solo sulla prima linea aggiungiamo il commento sul valore di theta
                        # attenzione questo cambia la dimensione del file
                        headerLine = False
                    else:
                        # tutti gli altri commenti restano inalterati
                        out = line
                else:
                    # e' una linea della sequenza su questa possiamo cambiare le basi
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

                        if (verbose and i > 0 and i % mb == 0):
                            written += 1
                            print( f"{written} / {totalSize}\r", end="")
                            
                    out = "".join(s)
                    totLen += len(line) - 1

                outText.write(out) # \n are in the original strings
                m = totLen // mb
                if (m > written):
                    written = m
                    if (verbose):
                        print( f"{written} / {totalSize}\r", end="")

    if (verbose):
        print(f"\n{outFile} -> {subst}/{totLen} ({subst*100/totLen:5.3f}%) substitutions")



if __name__ == "__main__":
    if (len(sys.argv) != 3):
        print(f"Errore nei parametri:\nUsage: {os.path.basename(sys.argv[0])} InputSequence thetaProbability")
        exit(-1)
    else:
        inputFile = sys.argv[1]
        theta = float(sys.argv[2])
        baseName, ext = os.path.splitext( inputFile)
        outFile = f"{baseName}-T={theta:05.3f}{ext}"
    
        ModifySequence(inputFile, outFile, theta, True)
