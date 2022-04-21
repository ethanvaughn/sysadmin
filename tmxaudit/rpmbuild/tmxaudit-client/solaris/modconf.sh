#!/bin/bash

# Script to make the necessary modifications to the /etc/syslog.conf file.

# Globals
CONF=/etc/syslog.conf

for facility in "authpriv.*" "cron.*" "*.info"; do
	facilitymissing=false
	(grep "${facility}.*@loghost" $CONF) || facilitymissing=true;
	if $facilitymissing; then
		# Append the facility to the end of the file: 
		printf "${facility}\t\t@loghost\n" >> $CONF
	fi
done

exit 0
