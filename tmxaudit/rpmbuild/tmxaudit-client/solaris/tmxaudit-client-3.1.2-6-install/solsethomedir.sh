#!/bin/bash

# Script to ensure the canned home dirs exist and have correct perms.

# Standard Tomax home dir:
HOMEDIR=/u01/home

# The two arrays link the name of the directory with the name of the group
# that will have setgid ownership. For example, the /u01/home/sysdba dir will
# be setgid to the "dba" group; whereas /u01/home/sysadmin will be setgid to
# the "sysadmin" group.
#
# Note: you must change the range in the 'for' loop's "seq" to encompass 
# all array elements whenever you add to this list.
#
DIRS[0]="sysdba"
SGID[0]="dba"

DIRS[1]="sysadmin"
SGID[1]="sysadmin"

DIRS[2]="sysdev"
SGID[2]="sysdev"


for i in 0 1 2; do
	# Make sure the home dir exists (the %install section of the spec should
	# have already done this, but just to be sure ...)
	mkdir -p $HOMEDIR/${DIRS[$i]}
	echo -n "Setting the home permissions for [${DIRS[$i]}] ..."
	chmod 2770 $HOMEDIR/${DIRS[$i]}
	mkdir -p $HOMEDIR/${DIRS[$i]}/.ssh
	touch $HOMEDIR/${DIRS[$i]}/.ssh/known_hosts
	if [ ! -f $HOMEDIR/${DIRS[$i]}/.bash_profile ]; then
		echo "export PATH=$PATH:/usr/local/bin:/usr/local/sbin" > $HOMEDIR/${DIRS[$i]}/.bash_profile
		echo "export PS1='[\u@\h \W]\$ '" >> $HOMEDIR/${DIRS[$i]}/.bash_profile
	fi
	if [ ! -f $HOMEDIR/${DIRS[$i]}/.bashrc ]; then
		echo "alias ll='ls -lh'" > $HOMEDIR/${DIRS[$i]}/.bashrc
	fi
	chown -R root:${SGID[$i]} $HOMEDIR/${DIRS[$i]}
	chmod -R g+rw $HOMEDIR/${DIRS[$i]}
	# Backup the .bash_profile before modifying
	[ -f $HOMEDIR/${DIRS[$i]}/.bash_profile ] && cp -f $HOMEDIR/${DIRS[$i]}/.bash_profile $HOMEDIR/${DIRS[$i]}/.bash_profile.bak
	(grep "tmxauditrc" $HOMEDIR/${DIRS[$i]}/.bash_profile) || /bin/echo "if [ -f ~/.tmxauditrc ]; then . ~/.tmxauditrc; fi" >> $HOMEDIR/${DIRS[$i]}/.bash_profile;
	find $HOMEDIR/${DIRS[$i]} -type d  | xargs chmod g+s
	echo " complete."
done

