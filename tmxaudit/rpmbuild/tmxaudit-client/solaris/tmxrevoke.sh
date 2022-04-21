#!/bin/bash

# Revoke root access granted to the dba in the /etc/sudoers file. Place
# this in the crontab as the expiration of the maintenance window at the 
# time you assign root access to the dba group.

SUDOERS=/usr/local/etc/sudoers
TMPFILE=/tmp/$(date "+%N")

# Disable the full access directive:
/bin/sed 's/^%dba.*ALL.*NOPASSWD:.*ALL$/#&/' $SUDOERS > $TMPFILE

# Update the file:
/bin/cp $TMPFILE $SUDOERS

# Cleanup:
/bin/rm -f $TMPFILE

exit 0
