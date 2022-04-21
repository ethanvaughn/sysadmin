#!/bin/bash
#
# reset-settlement-status.sh
#
#  Wrapper to send_nsca to send recovery to the service 
#  "ISD Settlement Status [DBA PAGER]" for this host.
#
#  Requires the following variables to be parsed from the
#  /u01/app/adminscripts/tmxaudit.properties file:
#
#          NAGIOS_DATACENTER
#          NAGIOS_HOSTNAME
#          NAGIOS_SERVER
# 

. /etc/TMXHOST.properties



#----- main -------------------------------------------------------------------
/u01/app/utils/send_nsca_recovery "Pivotlink Analytics [DBA PAGER]" "Manual run of Pivotlink analytics successful." $NAGIOS_DATACENTER


exit 0
