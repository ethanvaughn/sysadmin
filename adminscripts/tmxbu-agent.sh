#!/bin/bash

# Simple backup script.
#
# Read a list of files and directories to backup.
#
# Creates a TAR named "date-hostname.tar.gz", then uses
# the tmxaudit ssh key provided by the tmxaudit-client RPM package to
# copy the tar up to loghost. Places the file into the clientbu/<hostname>
# directory in the tmxaudit user's home directory on the loghost machine.

function usage_exit {
	echo
	echo "usage: $0 filename"
	echo
	echo "    filename: path to file that lists the directories to back up."
	echo
	exit 1
}

if [ $# -ne 1 ]; then 
	usage_exit
fi

DATE=$(date "+%Y%m%d")
HOSTNAME=$(hostname | cut -d "." -f1 | tr 'A-Z' 'a-z')
LISTFILE=$1
BUFILENAME=$DATE-$HOSTNAME.tar.gz
BUFILE=/u01/app/adminscripts/$BUFILENAME

# Make sure the remote directory exists:
/usr/bin/ssh tmxaudit@loghost "mkdir -p clientbu/$HOSTNAME"

# Create the backup file:
/bin/tar czf $BUFILE $(/bin/cat $LISTFILE)

# Copy to the loghost box:
/usr/bin/scp $BUFILE tmxaudit@loghost:clientbu/$HOSTNAME/

# Cleanup:
/bin/rm -f $BUFILE

exit 0
