#!/bin/bash

function usage_exit {
	echo 
	echo "Revoke root access granted to the user in the /etc/sudoers file. Place"
	echo "this in \"cron\" or \"at\" as the expiration of the maintenance window at the" 
	echo "time you assign root access to the dba group."
	echo  "Usage: $0 user"
	echo
	echo "    user = Login account of the user to remove from the sudoers."
	echo
	exit 1
}

if [ $# -ne 1 ]; then 
	usage_exit
fi

USER=$1

SUDOERS=/etc/sudoers
TMPFILE=/tmp/$(date "+%N")

# Check for existing TMPFILE and wait for it to clear up.
if [ -e $TMPFILE ]; then
	sleep 2
fi

# Disable the full access directive:
/bin/sed "s/^$USER.*ALL.*NOPASSWD:.*ALL$//" $SUDOERS > $TMPFILE

# Trim and update the file:
/u01/app/adminscripts/trim.awk < $TMPFILE > $SUDOERS

# Cleanup:
/bin/rm -f $TMPFILE

exit 0
