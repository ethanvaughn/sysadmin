#!/bin/bash


function usage_exit {
	echo
	echo "Create a rotating backup of the specified file. The default action is"
	echo "to create a new empty file."
	echo
	echo "Use the '-k' argument to keep the file 'as is' for non-log files (eg. passwd)."
	echo "You can use the '-m' argument to just move the file without creating an"
	echo "empty one for applications that create their own file."
	echo
	echo "usage: $0 infile num [-k] [-m]"
	echo 
	echo "    infile = Full path of the file to rotate."
	echo "    num = Number of backup files to keep."
	echo "    -k = [optional] Keep the file contents without wiping between rotations."
	echo "    -m = [optional] Move the file without creating a new one."
	echo
	echo "    Note: The -k and -m args are mutually exclusive. Argument position"
	echo "    matters: the script only recognizes the first 3 args and ignores"
	echo "    the rest."
	echo
	echo "Example:"
	echo "    $0 mylogfile.log 3"
	echo "    $0 /etc/passwd 10 -k"
	echo "    $0 app.debug 5 -m"
	echo
	exit 1
}

if [ $# -lt 2 ]; then
	usage_exit
fi

FILE=$1
NUM=$2

# Wipe is the default. Turn off if specified.
WIPE=Y
if [ "X${3}" == "X-k" ]; then
	WIPE=N
fi

MOVE=N
if [ "X${3}" == "X-m" ]; then
	MOVE=Y
fi

for i in $(seq $[ $NUM - 1 ] 1); do
	if [ -f $FILE.$i ]; then
		j=$[ $i + 1 ]
		cp -p $FILE.$i $FILE.$j
	fi
done

if [ $WIPE = "N" ]; then
	cp -p $FILE $FILE.1
else
	mv $FILE $FILE.1
	if [ $MOVE = "N" ]; then
		>$FILE
	fi
fi

