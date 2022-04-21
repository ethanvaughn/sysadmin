#!/bin/bash


function usage_exit  {
	echo
	echo "Usage: $0 logdir"
	echo
	exit 1
}

if [ ! -d $1 ]; then 
	usage_exit
fi

for i in $1/*; do
	echo
	echo [$i]
	cat $i
done

echo

exit 0