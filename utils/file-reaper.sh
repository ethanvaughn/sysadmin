#!/bin/bash

# Full path to commands:
FIND=$(which find)
if [ $? -ne 0 ]; then
	echo
	echo "**ERROR**  Command [find] is not in path."
	echo
	exit 1
fi

XARGS=$(which xargs)
if [ $? -ne 0 ]; then
	echo
	echo "**ERROR**  Command [xargs] is not in path."
	echo
	exit 1
fi



#----- usage-exit ------------------------------------------------------------
function usage_exit {
	echo
	echo "Purge expired files from a directory."
	echo
	echo "Usage: $0 days directory"
	echo "  days = Number of days to keep in the directory based on mtime."
	echo
	echo "eg."
	echo "$0 30 /u01/app/logs"
	echo
	exit 1
}



#----- main ------------------------------------------------------------------
if [ $# -ne 2 ]; then
	usage_exit
fi

typeset -i DAYS=$1
BU_DIR=$2

if [ ! -d $BU_DIR ]; then
	echo
	echo "**ERROR**  The path [$BU_DIR] does not exist or is not a directory."
	echo
	usage_exit
fi

$FIND $BU_DIR -mtime +$DAYS -type f | xargs rm -fv

exit 0
