#!/bin/sh

# $Id: Launcher.sh,v 1.5 2009/10/14 18:30:35 evaughn Exp $
# $Date: 2009/10/14 18:30:35 $


#----- usage_exit -------------------------------------------------------------
function usage_exit {
	echo
	echo "$0 hostname IP cust_code \"Service Description\" \"Class Name\" timeout"
	echo
	exit 1
}




#----- Globals ----------------------------------------------------------------
JAVAHOME='/u01/app/java'
LIBEXEC='/u01/app/nagios/libexec'
BASEDIR='/u01/home/nagios/monitoring'




#----- main -------------------------------------------------------------------
if [ $# -ne 6 ]; then
	usage_exit
fi

# Process the command line args
HOSTNAME=$1
IP=$2
CUST_CODE=$3
# Strip the end tag, strip the trailing whitespace, replace spaces with underscores:
SERVICE=$(echo $4 | sed 's/\[.*\]/ /g' | sed 's/ *$//' | sed 's/ /_/g')

CLASS=`echo $5 | sed 's/ /_/g'`;
TIMEOUT=$6

cd $LIBEXEC;
$JAVAHOME/bin/java -classpath $LIBEXEC/lib:$LIBEXEC/lib/ojdbc5.jar:. Launcher $HOSTNAME $IP $CUST_CODE $SERVICE $CLASS $BASEDIR $TIMEOUT

exit 0
