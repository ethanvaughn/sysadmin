#!/bin/bash


#----- usage_exit ------------------------------------------------------------
function usage_exit {
	echo
	echo "Create a local system account on the box."
	echo
	echo "Creates a home directory in /u01/home/USERNAME and creates the user"
	echo "without a password, but gives the %sysdba and %syssup groups sudo"
	echo "access to the account. Use the optional group to assign a primary"
	echo "group other than user private group."
	echo
	echo "Uses the /u01/app/adminscrips/nextuid.pl script to auto-assign uid."
	echo 
	echo "** NOTE ** The arguments are position dependent."
	echo
	echo "Usage: $0 user [group]"
	echo
	echo "    user = Login account of the user."
	echo "    group = [Optional] primary group."
	echo
	echo "eg. $0 jrandom kmdba"
	echo
	exit 1
}



#----- Main ------------------------------------------------------------------
if [ $# -lt 1 ]; then
	echo 
	echo "** ERROR: Missing Required Parameters **"
	echo 
	usage_exit
fi

# Gather the command-line parameters: 
USERNAME=$1
GROUP=$2

HOMEDIR="/u01/home/${USERNAME}"

if [ $GROUP ]; then
	/usr/sbin/tmxuseradd -u $(/u01/app/adminscripts/nextuid.pl) -g $GROUP -c "System Account" -d $HOMEDIR $USERNAME
else
	/usr/sbin/tmxuseradd -u $(/u01/app/adminscripts/nextuid.pl) -c "System Account" -d $HOMEDIR $USERNAME
fi

echo "Appending sudo access:"
SUDO_CMD="%sysdba,%syssup ALL=(ALL) NOPASSWD: /bin/su - $USERNAME"
echo "    $SUDO_CMD"
echo "$SUDO_CMD" >> /etc/sudoers

exit 0
