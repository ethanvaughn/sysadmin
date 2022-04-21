#!/bin/bash

if [ "X$1"  = 'X' ]; then
	echo "Unable to execute: please provide data center password."
fi

PASSWORD=$1
USERNAME="evaughn"
LOGDIR="/tmp/chkvnc"
SENDCMD="/u01/app/utils/sendcmd/bin/sendcmd.pl"
HOSTLIST="/u01/app/utils/sendcmd/lists/vnc.list"

$SENDCMD -u $USERNAME -p $PASSWORD -l $LOGDIR -f $HOSTLIST -c "ps -A -o user,pid,args | grep -i [X]vnc | tr -s ' ' | cut -d ' ' -f 1,2,3,4,5,7"
if [ $? -ne 0 ]; then
	exit 1
fi

# Create the report:
echo "Weekly VNC Server Report" > $LOGDIR/vnc.report
echo "" >> $LOGDIR/vnc.report
echo "The following list shows the username, PID, and X display of VNC Server" >> $LOGDIR/vnc.report
echo "instances currently running. Please check the list for instances you are" >> $LOGDIR/vnc.report
echo "running and close them as appropriate." >> $LOGDIR/vnc.report
echo "------------------------------------------------------------------------" >> $LOGDIR/vnc.report
echo "" >> $LOGDIR/vnc.report
for i in $(<$HOSTLIST); do
	fsize=$(ls -l $LOGDIR/$i.log | tr -s " " | cut -d " " -f5)
	if [ $fsize -gt 100 ]; then
		echo >> $LOGDIR/vnc.report; 
		echo [$i] >> $LOGDIR/vnc.report; 
		tail -n+2 $LOGDIR/$i.log >> $LOGDIR/vnc.report; 
	fi
done

# Email the report:
cat $LOGDIR/vnc.report | /u01/app/utils/mail.pl -s "WEEKLY VNC REPORT" dbagroup@tomax.com,sysadmin@tomax.com

# clean up 
rm -rf $LOGDIR

exit 0