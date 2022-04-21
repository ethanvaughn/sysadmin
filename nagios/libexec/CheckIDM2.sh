#!/bin/sh

##################################################################################################################
#
# Purpose: Wrapper for CheckIDM (because of Java Classpath lameness)
#
# $Id: CheckIDM2.sh,v 1.1 2010/04/22 23:35:04 evaughn Exp $
# $Date: 2010/04/22 23:35:04 $
#
##################################################################################################################
CLASSPATH=.:/u01/app/nagios/libexec:/u01/app/nagios/libexec/lib:/u01/app/nagios/libexec/lib/java-getopt-1.0.13.jar:/u01/app/nagios/libexec/lib/idm-client-2.2-all.jar:/u01/app/nagios/libexec/lib/jbossall-client.jar 

export CLASSPATH
cd /u01/app/nagios/libexec/
/u01/app/java/bin/java CheckIDM2 "$@"
