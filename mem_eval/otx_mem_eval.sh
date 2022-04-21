#!/bin/bash

logfile=~/mem_eval/otx_mem_eval.log

# For each otxserv pid:
declare -i num_ps=0
declare -i tot_rss=0
declare -i rss=0;
for i in $(~/mem_eval/ps_otxserv.sh  | awk -F " " '{print $2;}'); do 
	# Use /proc/PID directly (much faster than 'ps' cmd)
	rss=$(cat /proc/${i}/status | grep '^VmRSS' | awk '{print $2}')
	tot_rss=$[ $tot_rss + $rss ];
	num_ps=$[ $num_ps + 1 ];
done

declare -i mem_use=$(free | grep '^[-][/][+]' | awk '{print $3}')

if [ ! -f ${logfile} ]; then
	printf "otx_serv Process Memory Profile\n\n" >> $logfile

	printf "time              num_ps      avg_rss         tot_rss        mem_used\n" >> $logfile
	printf "_________________ ______ ____________ _______________ _______________\n" >> $logfile
fi

declare -i avg_rss=0
if [ $num_ps -gt 0 ]; then
	avg_rss=$[ $tot_rss / $num_ps ]
fi
printf "%17s %6d %9d kB %12d kB %12d kB\n" "$(date '+%Y%m%d %H:%M:%S')" $num_ps $avg_rss $tot_rss $mem_use >> $logfile

