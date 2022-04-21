#!/bin/bash

# Script to make the necessary modifications to the /etc/syslog.conf file.

# Globals
conf=/etc/syslog.conf
work=/tmp/syslog.conf.tmxaudit
tmp=/tmp/syslog.conf.tmp

fifomissing=false

# Make a working copy of current syslog.conf
cp $conf $work

# Make the changes to the working copy:
for logfile in messages secure cron; do
	(grep -q "${logfile}[.]fifo" /etc/syslog.conf) || fifomissing=true;
	if $fifomissing; then
		# Extract the facility line into a var for later use:
		pattern="\/var\/log\/${logfile}$"
		line=$(grep "$pattern" $work)
		# Comment out the existing facility:
		sed 's_^.*/var/log/'"$logfile"'$_#&_' $work >$tmp 
		# Write the fifo facility:
		echo "${line}.fifo" >> $tmp; 
		cp -f $tmp $work;
	fi
done

if $fifomissing; then
	cp -f $work $conf
fi

rm -f $work $tmp

exit 0
