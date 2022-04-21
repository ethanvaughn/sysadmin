#!/bin/sh

# Purpose:	Runs Nagios Java Framework monitoring scripts, and instead of just printing to STDOUT, builds a passive check
#		and submits it to the Nagios FIFO
# $Id: Launcher_Passive.sh,v 1.1 2008/03/13 21:52:27 jkruse Exp $
# $Date: 2008/03/13 21:52:27 $

FIFO='/u01/app/nagios/var/rw/nagios.cmd';
DIRECTORY='/u01/home/nagios/monitoring';
SERVICE=`echo $4 | sed 's/ /_/g'`;
CLASS=`echo $5 | sed 's/ /_/g'`;
cd /u01/app/nagios/libexec/;
# Run Java and store output/exit code into $OUTPUT,$CODE
OUTPUT=`/u01/app/java/bin/java -classpath /u01/app/nagios/libexec/lib:/u01/app/nagios/libexec/lib/ojdbc6.jar:. Launcher $1 $2 $3 $SERVICE $CLASS $DIRECTORY $6`
CODE=$?
# Now build passive check
NOW=`date +%s`;

/usr/bin/printf "[%lu] PROCESS_SERVICE_CHECK_RESULT;$1;$4;$CODE;$OUTPUT\n" $NOW > $FIFO
