#!/bin/bash


#----- usage_exit ------------------------------------------------------------
function usage_exit {
	echo
	echo "Grant sudo access for a login user to a system account."
	echo 
	echo "Usage: $0 user system [hours]"
	echo
	echo "    user   = Login account of the user requiring access."
	echo "    system = The system account (eg. oracle)."
	echo "    hours  = Number of hours for the access window (use 0 for permanent)."
	echo
	echo "eg. $0 jrandom oracle 48"
	echo "eg. $0 permanentuser oas 0"
	echo
	exit 1
}



#----- user_not_found --------------------------------------------------------
function user_not_found {
	echo
	echo "User [$1] not found. Please check the spelling of the username."
	echo
	exit 1
}



#----- system_not_found --------------------------------------------------------
function system_not_found {
	echo
	echo "System account [$1] not found. Please check the spelling of the account name."
	echo
	exit 1
}



#----- Main ------------------------------------------------------------------
if [ $# -ne 3 ]; then 
	usage_exit
fi

# Gather the command-line parameters: 
USER=$1
SYSTEM=$2
typeset -i HOURS=$3


$(grep $USER   /etc/passwd >/dev/null) || user_not_found   $USER
$(grep $SYSTEM /etc/passwd >/dev/null) || system_not_found $SYSTEM

if [ $HOURS -lt 0 ]; then
	echo
	echo "Please enter a valid number of hours for the grant. Use 0 for permanent."
	echo
	usage_exit
fi

# Global definitions:
SED=$(which sed)
AT=$(which at)
SUDOERS=/etc/sudoers
TMPFILE=/tmp/$(date "+%s")

DIRECTIVE="$USER ALL=(ALL) NOPASSWD: /bin/su - $SYSTEM"

RESULT=1

if [ $HOURS -gt 0 ]; then
	echo "Scheduling the revocation:"
	echo "/u01/app/adminscripts/revokeSudo.sh $USER $SYSTEM" | $AT now + $HOURS hours
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
		echo
		echo "*** Unable to schedule for [$HOURS] hours. ***"
		echo
		usage_exit
	fi
fi

# Insert the sudo access directive:
echo "${DIRECTIVE}" >> $SUDOERS

echo
if [ $HOURS -eq 0 ]; then 
	echo -n "**PERMANENT** "
else
	echo -n "**TEMPORARY** "
fi 
echo "Sudo access to the [$SYSTEM] account has been granted for user [$USER]."
echo

exit 0
