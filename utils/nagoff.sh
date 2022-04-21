#!/bin/bash
# Nagios nagoff.sh
# Version 1.1
#  ***********************************************
# This script turns off monitoring for the nagios services
# If a parameter is passed it will be used for the service to disable or if no parameter is passed
# all services will be disabled for host.

if [ -z $1 ]; then
	/u01/app/utils/nagios-notify.pl -A off
else
	/u01/app/utils/nagios-notify.pl -A off -S "$1"
fi

exit 0