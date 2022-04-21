#!/bin/bash




#----- Globals --------------------------------------------------------
ECHO=$(which echo)
RM=$(which rm)
SLEEP=$(which sleep)




#----- usage_exit ----------------------------------------------------------
function usage_exit {
	$ECHO
	$ECHO "Delete all files from the specified directory with a pause"
	$ECHO "between each deletion."
	$ECHO
	$ECHO "Usage: $0 seconds path glob"
	$ECHO 
	$ECHO "    seconds: Time to wait between each deletion (must be > 5)."
	$ECHO "       path: Path from which to delete files."
	$ECHO "       glob: File globbing pattern of files to delete."
	$ECHO
	$ECHO "    eg. "
	$ECHO "    $0 7  /u01/app/datadir '*.txt'"
	$ECHO "    $0 15 /u01/app/datadir '*.log *.dbf'"
	$ECHO 
	$ECHO "    Note: You must quote your glob pattern as shown above."
	$ECHO
	exit 1
}




#----- main ------------------------------------------------------------
if [ $# -ne 3 ]; then
	usage_exit
fi

SEC=$1
PATH=$2
GLOB=$3

if [ $SEC -lt 5 ]; then
	$ECHO
	$ECHO "*** ERROR *** Please specify a time-to-wait that is greater than 4 seconds."
	usage_exit
fi

cd $PATH
echo
echo "----- Deleting files from dir $(pwd) -----"
for i in $GLOB; do
	$RM -fv $i
	$SLEEP $SEC
done


exit 0
