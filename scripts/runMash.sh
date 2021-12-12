#! /bin/bash

tmp=tmp.$$
path=~/results/Escherichiacoli

gammas='000 005 010 050 100 200 300 500'
kMin=10
kMax=32
model='EscherichiaColi'

results=$model.csv

k=$kMin
while ((k < kMax)); do
    echo "Sketch for k = $k"
    mash sketch -k $k ${model}.fasta

    for g in $gammas; do
	echo "Distances for gamma = $g"
	mash sketch -k $k ${model}-G=0.$g.fasta
	mash dist ${model}.fasta.msh ${model}-G\=0.$g.fasta.msh > $tmp
	distance=$(cat $tmp | cut -f 3-3)
	echo "$model, 0.$g, $k, $distance" >> $results

    done # for each gamma
    ((k += 2))
done # for each k

rm $tmp
