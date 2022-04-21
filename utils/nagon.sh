#!/bin/bash
# Nagios nagon.sh
# Version 1.1
#  ***********************************************
# This script turns on monitoring for the nagios service
# If a parameter is passed it will be used for service to enable or if no parameter is passed
# all services will be enabled.

if [ -z $1 ]; then
	/u01/app/utils/nagios-notify.pl -A on
else
	/u01/app/utils/nagios-notify.pl -A on -S "$1"
fi

exit 0