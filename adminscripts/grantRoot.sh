#!/bin/bash


#----- usage_exit ------------------------------------------------------------
function usage_exit {
	echo
	echo "Grant root access to the dba group in the /etc/sudoers file."
	echo 
	echo "Usage: $0 user hours"
	echo
	echo "    user  = Login account of the user requiring access."
	echo "    hours = Number of hours for the root-access window."
	echo
	echo "eg. $0 jrandom 48"
	echo
	exit 1
}



#----- user_not_found --------------------------------------------------------
function user_not_found {
	echo
	echo "User $1 not found. Please check the spelling of the username."
	echo
	usage_exit
}


#----- Main ------------------------------------------------------------------
if [ $# -ne 2 ]; then 
	usage_exit
fi

# Gather the command-line parameters: 
USER=$1
typeset -i HOURS=$2


$(grep $USER /etc/passwd >/dev/null) || user_not_found $USER

if [ $HOURS -lt 1 ]; then
	echo
	echo "*** Please indicate the number of hours for the grant (>0). ***"
	echo
	usage_exit
fi

# Global definitions:
SED=$(which sed)
AT=$(which at)
SUDOERS=/etc/sudoers
TMPFILE=/tmp/$(date "+%s")

DIRECTIVE="$USER        ALL=(ALL) NOPASSWD: ALL"

RESULT=1

echo "Scheduling the revocation:"
echo "/u01/app/adminscripts/revokeRoot.sh $USER" | $AT now + $HOURS hours
RESULT=$?
if [ $RESULT -ne 0 ]; then
	echo
	echo "*** Unable to schedule for $HOURS hours. ***"
	echo
	usage_exit
fi

# Insert the full access directive:
echo "${DIRECTIVE}" >> $SUDOERS

echo 
echo "Root access has been granted for user [$USER]."
echo

exit 0
