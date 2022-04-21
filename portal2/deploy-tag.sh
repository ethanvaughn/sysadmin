#!/bin/bash


#---- usage_exit ---------------------------------------------------------------
function usage_exit {
	echo
	echo "Usage: $0 TAG"
	echo
	echo "    Where 'TAG' is 'TEST' or 'PROD'"
	echo
	exit 1
}



#----- main ------------------------------------------------------------------
if [ -z $1 ]; then
	usage_exit
fi

TAG=$1

cvs -q tag -F $TAG \
	./bin/get_hostdata.pl \
	./cgi \
	./conf/portal.conf \
	./html \
	./lib \
	./var


exit 0
