#!/bin/bash


#----- usage_exit ------------------------------------------------------------
function usage_exit {
	echo
	echo "Create a local user on the box."
	echo
	echo "Creates a home directory in /u01/home/USERNAME. Assigns the "
	echo "user name as the password and requires the user to change "
	echo "password on initial login. Use the optional group to assign"
	echo "a primary group other than user private group."
	echo
	echo "Uses the /u01/app/adminscrips/nextuid.pl script to auto-assign uid."
	echo 
	echo "** NOTE ** The arguments are position dependent."
	echo
	echo "Usage: $0 user \"Full Name\" [group]"
	echo
	echo "    user = Login account of the user."
	echo "    \"Full Name\" = Full name of the user."
	echo "    group = [Optional] primary group."
	echo
	echo "eg. $0 jrandom \"Jay Random\" kmdba"
	echo
	exit 1
}



#----- Main ------------------------------------------------------------------
if [ $# -lt 2 ]; then
	echo 
	echo "** ERROR: Missing Required Parameters **"
	echo 
	usage_exit
fi

# Gather the command-line parameters: 
USERNAME=$1
FULLNAME=$2
GROUP=$3

HOMEDIR="/u01/home/${USERNAME}"

if [ $GROUP ]; then
	/usr/sbin/tmxuseradd -u $(/u01/app/adminscripts/nextuid.pl) -g $GROUP -c "$FULLNAME" -d $HOMEDIR $USERNAME
else
	/usr/sbin/tmxuseradd -u $(/u01/app/adminscripts/nextuid.pl) -c "$FULLNAME" -d $HOMEDIR $USERNAME
fi
echo $USERNAME | passwd $USERNAME --stdin

# Require user to change passwd upon initial login, but password will not expire for approx. 10 years.
chage -M 3000 -d 113 $USERNAME

echo 
echo "** REMINDERS **"
echo "To expire the account use the 'chage -E YYYY-MM-DD' command: chage -E 2008-05-24 $USERNAME"
echo
echo "Use the /u01/app/adminscripts/grantSudo.sh to grant system account access (eg. oracle)."
echo

exit 0
