#!/bin/bash

OUTPUT_JSON="network_usage.json"

echo "[" > $OUTPUT_JSON

sudo nettop -P -L 1 -J bytes_in,bytes_out,process -x -l 1 | \
grep -v "bytes_" | \
awk -F, '
{
    process=$1
    bytes_in=$2
    bytes_out=$3

    gsub(/"/,"",process)

    printf("{\"process\":\"%s\",\"bytes_in\":%s,\"bytes_out\":%s},\n",process,bytes_in,bytes_out)
}' >> $OUTPUT_JSON

sed -i '' '$ s/,$//' $OUTPUT_JSON

echo "]" >> $OUTPUT_JSON

echo "Network data saved to $OUTPUT_JSON"
