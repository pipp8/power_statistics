#! /usr/bin/bash

export LC_ALL=en_US.UTF-8 

prev=$(hdfs dfs -ls  -t synthetics | head -2 | tail -1 | awk '{ print $5 }')
delay=10
clear
lastLine=$(stty size | cut -d ' ' -f 1)
lastLine=$((lastLine - 1))

tput cup $lastLine 0
echo -n "waiting results                        "
while true; do
    sleep $delay
    new=$(hdfs dfs -ls  -t synthetics | head -2 | tail -1 | awk '{ print $5 }')
    tput cup $lastLine 0
    echo -n "$(numfmt --grouping $new) -> $(((new - prev) / (1024*1024*delay))) Mb/s   "
    prev=$new
done

