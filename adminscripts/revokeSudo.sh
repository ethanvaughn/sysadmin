#!/bin/bash

function usage_exit {
	echo 
	echo "Revoke sudo access granted to the user in the /etc/sudoers file. Place"
	echo "this in \"cron\" or \"at\" as the expiration of the maintenance window at the" 
	echo "time you assign sudo access to the user."
	echo 
	echo  "Usage: $0 user system"
	echo
	echo "    user   = Login account of the user to remove from the sudoers."
	echo "    system = The system account (eg. oracle)."
	echo
	exit 1
}

if [ $# -ne 2 ]; then 
	usage_exit
fi

USER=$1
SYSTEM=$2

SUDOERS=/etc/sudoers
TMPFILE=/tmp/$(date "+%N")


# Avoid race condition
if [ -e $TMPFILE ]; then
	sleep 2
fi

# Disable the sudoers directive:
/bin/sed "s/^${USER}.*ALL.*NOPASSWD:.*${SYSTEM}$//" $SUDOERS > $TMPFILE

# Trim and update the file:
/u01/app/adminscripts/trim.awk < $TMPFILE > $SUDOERS

# Cleanup:
/bin/rm -f $TMPFILE

exit 0
