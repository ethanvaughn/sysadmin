#!/bin/bash

# Full path to commands:
LS=$(which ls)
RMDIR=$(which rmdir)
FILE_REAPER=/u01/app/utils/file-reaper.sh
if [ ! -f $FILE_REAPER ]; then
	echo
	echo "**ERROR**  Command [] is missing."
	echo
	exit 1
fi

# Globals:
BU_HOME=/u01/home/tmxaudit/clientbu
if [ ! -d $BU_HOME ]; then
	echo
	echo "**ERROR**  The path BU_HOME: [$BU_HOME] is missing."
	echo
	exit 1
fi

BU_LIST=$($LS -1 $BU_HOME)
typeset -i DAYS=30

#----- main ------------------------------------------------------------------
cd $BU_HOME
for clientdir in $BU_LIST; do
	echo [$clientdir]
	$FILE_REAPER $DAYS $clientdir
	$RMDIR --ignore-fail-on-non-empty $clientdir
	echo
done

exit 0
	