#!/bin/sh


function usage_exit {
	echo
	echo "Write a command to the Nagios command file to cause"
	echo "it to process a service check result."
	echo
	echo usage: $0 host_name "service_desc" return_code "plugin_output"
	echo

	exit 1
}

 


#----- main -------------------------------------------------------------------
if [ $# -ne 4 ]; then
	usage_exit 
fi

ECHO="/bin/echo"
nagios_cmd="/u01/app/nagios/var/rw/nagios.cmd"
if [ ! -e $nagios_cmd ]; then
	echo "Nagios fifo missing [$nagios_cmd] or Nagios service not running."
	exit 3
fi

# Get the current date/time in seconds since UNIX epoch
NOW_EPOCH=$(date +%s)

# Create the command line to add to the command file
cmdline="[$NOW_EPOCH] PROCESS_SERVICE_CHECK_RESULT;$1;$2;$3;$4"

# Append the command to the end of the command file
$ECHO $cmdline >> $nagios_cmd

exit 0