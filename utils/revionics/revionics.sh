#!/bin/bash
# revionics.sh


if [ ! -f $HOME/scripts/setupenv.sh ]; then
	echo
	echo "** ERROR ** Config file missing: $HOME/scripts/setupenv.sh"
	echo "    Please run script as the appropriate user."
	exit 1
fi
. $HOME/scripts/setupenv.sh


# Load NAGIOS_HOSTNAME, NAGIOS_DATACENTER
if [ ! -f /etc/TMXHOST.properties ]; then
	echo
	echo "** ERROR ** Config file missing: /etc/TMXHOST.properties"
	echo "    Server misconfigured. Contact SA team."
	exit 1
fi
. /etc/TMXHOST.properties




#----- validate_properties ---------------------------------------------------
function validate_properties {
	UTIL_PATH=/u01/app/utils/revionics
	PROPERTIES=$UTIL_PATH/revionics.properties

	if [ ! -f $PROPERTIES ]; then
		echo
		echo "** WARNING ** Properties file missing: "
		echo "    Creating empty $PROPERTIES file."
		touch $PROPERTIES
	fi

	. $PROPERTIES

	if [ -z $EXPDIR ]; then
		echo
		echo "** WARNING ** EXPDIR not set in $PROPERTIES file."
		echo "    Defaulting EXPDIR to /u01/app/ftpdl/exp/PROD."
		echo "EXPDIR=/u01/app/ftpdl/exp/PROD" >> $PROPERTIES
	fi

	if [ -z "$REV_LOGIN" ]; then
		echo
		echo "** ERROR ** REV_LOGIN property not set in $PROPERTIES file."
		echo 'REV_LOGIN="open -u user,pass ftps://IPADDR"' >> $PROPERTIES
		exit 1
	fi

	if $(echo $REV_LOGIN | grep -q IPADDR); then
		echo
		echo "** ERROR ** REV_LOGIN property not set in $PROPERTIES file."
		exit 1
	fi
	
}




#----- Globals --------------------------------------------------------------
logdt=$(date "+%m%d%y%H%M%S")
TARFILE=revionics_${logdt}.tar.gz
CMDFILE=/tmp/revionics-ftp-${logdt}




#----- main -------------------------------------------------------------------
echo "========================================================================"
echo
echo "BEGIN Processing Revionics for [ $(date) ]"
echo

validate_properties

cd $EXPDIR

echo "Archiving export files in dir $(pwd) ..."
tar cvzpf $TARFILE C*psv D*psv P*psv S*psv V*psv 
if [ $? -eq 0 ]; then
   echo "Tar command successful!  Removing export files."
   rm -f C*psv D*psv P*psv S*psv V*psv
else
   echo "Tar command failed!"
   exit 1
fi

echo "Sending tar file to Revionics ..."
# Create the command file used by the lftp command.
echo $REV_LOGIN > $CMDFILE
if [ $? -ne 0 ]; then
   echo "Unable to write to file: $CMDFILE!"
   exit 1
fi
echo "put $TARFILE" >> $CMDFILE

# Send the file:
/usr/bin/lftp -f $CMDFILE
if [ $? -ne 0 ]; then
   echo "File transfer failed!"
   exit 1
fi

echo "File transfer successful!"
mv $TARFILE archive
find $EXPDIR/archive -mtime +30 -exec rm {} \;

# Clean up the tmp files:
rm -f $CMDFILE

exit 0
