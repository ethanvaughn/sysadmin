#!/bin/bash

# Combines the CPU statistics for each day's stat log in the /var/log/sa/
# directory in to a single .csv file.

logdir=/var/log/sa
csvfile=${logdir}/$(hostname)-$(date '+%Y%m%d').csv

cd $logdir

>$csvfile
for file in sar*; do
	cat $file | head -n 1 | awk '{print $4}' >> $csvfile
	cat $file | grep 'all' | grep -v 'Average' | sed 's/ \+/,/g' | awk -F "," '{print $1 "," (100 - $7)}' >> $csvfile
done

