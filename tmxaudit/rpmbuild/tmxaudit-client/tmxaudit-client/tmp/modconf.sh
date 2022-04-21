#!/bin/bash

# Script to make the necessary modifications to the /etc/syslog.conf file.

# Globals
conf=/etc/syslog.conf

# Make the changes to the working copy:
# TODO: change to extract the facility string from logfiles (messages, cron,
# secure) entries and use them instead of hardcoding these.
# the 
for facility in "authpriv.*" "cron.*" "*.info"; do
	facilitymissing=false
	(grep -q "${facility}.*@loghost" /etc/syslog.conf) || facilitymissing=true;
	if $facilitymissing; then
		# Append the facility to the end of the file: 
		echo "${facility}          @loghost" >> $conf
	fi
done

exit 0
