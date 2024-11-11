#!/usr/bin/bash

if (( $# != 1 )); then
    echo "Errore nei parametri. Usage:\n $0 inputFile"
    exit -1
fi
    
inFile=$1
tmpFile=/tmp/tt.csv

(head -1 $inFile; grep -v "^model" $inFile) > $tmpFile

mv $tmpFile $inFile
