#!/bin/sh

##################################################################################################################
#
# Purpose: Wrapper for CheckRemoteSockets (because of Java Classpath lameness)
#
# $Id: CheckRemoteSockets.sh,v 1.1 2008/08/30 15:56:18 jkruse Exp $
# $Date: 2008/08/30 15:56:18 $
#
##################################################################################################################
CLASSPATH=.:/u01/app/nagios/libexec:/u01/app/nagios/libexec/lib:/u01/app/nagios/libexec/lib/java-getopt-1.0.13.jar

export CLASSPATH
cd /u01/app/nagios/libexec/;
/u01/app/java/bin/java CheckRemoteSockets "$@"
