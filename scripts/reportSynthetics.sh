#! /usr/bin/bash


baseSeq=$1

dataDir='/home/cattaneo/spark/power_statistics/Datasets'


base=$(basename $baseSeq .fna)
t=0.005
tt=$(printf "%s/%s-%s-T=%.3f-T=%.3f*.csv" $dataDir $base $base $t $t)
report=$(mktemp)

# salva l'header
head -1 $tt > $report
i=0
for f in ${dataDir}/${base}-${base}*.csv; do
    # f=$(printf "%s-%s-T=%.3f-T=%.3f*.csv" $base $base $t $t)
    echo -n "Processing file: $f -> "
    # aggiunge i risultati per ogni theta (senza header)
    tail +2 $f >> $report
    wc -l $report
    ((i++))
done

l=$(wc -l $report | cut -d ' ' -f 1)
# 8 x i + 1
tot=$((i * 8 + 1))
if (($l != $tot)); then
   echo "wrong number of lines $l"
   wc ${dataDir}/${base}*.csv
else
    echo $base ok $l
fi

final=${dataDir}/${base}-$(date +%s).csv

mv $report $final

