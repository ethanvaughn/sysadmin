#!/bin/sh

##################################################################################################################
#
# Purpose: Wrapper for CheckIDM (because of Java Classpath lameness)
#
# $Id: CheckIDM.sh,v 1.2 2009/08/18 22:11:57 evaughn Exp $
# $Date: 2009/08/18 22:11:57 $
#
##################################################################################################################
CLASSPATH=.:/u01/app/nagios/libexec:/u01/app/nagios/libexec/lib:/u01/app/nagios/libexec/lib/java-getopt-1.0.13.jar:/u01/app/nagios/libexec/lib/idm-client-1.3.1-all.jar:/u01/app/nagios/libexec/lib/jbossall-client.jar 

export CLASSPATH
cd /u01/app/nagios/libexec/
/u01/app/java/bin/java CheckIDM "$@"
