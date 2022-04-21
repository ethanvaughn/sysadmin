#!/bin/bash

# $Id: analytics_daily.sh,v 1.11 2010/04/27 23:05:51 evaughn Exp $
#
# To be run as the "oracle" user. Note, the standard; environment variable
# "HOME" must be available within the oracle user's cron environment.
#

# The HOME environment variable must be available. This should get set by the system.
if [ -z $HOME ]; then
	echo "** ERROR ** HOME environment variable not set."
	exit 1
fi
	

# Load NAGIOS_HOSTNAME, NAGIOS_DATACENTER
. /etc/TMXHOST.properties


# Load pivotlink properties (see below for required properties)
if [ ! -e /u01/app/utils/pivotlink/pivotlink.properties ]; then
	echo "** WARNING ** Properties file missing: /u01/app/utils/pivotlink/pivotlink.properties"
	echo "    Creating empty /u01/app/utils/pivotlink/pivotlink.properties file."
	touch /u01/app/utils/pivotlink/pivotlink.properties
fi
. /u01/app/utils/pivotlink/pivotlink.properties

# Basic validity tests for required properties
if [ -z $CUSTNAME ]; then
	echo "** ERROR ** CUSTNAME property not set in pivotlink.properties file: CUSTNAME = $CUSTNAME"
	echo "CUSTNAME=" >> /u01/app/utils/pivotlink/pivotlink.properties
	exit 1
fi
if [ -z $SSH_KEY ]; then
	echo "** WARNING ** SSH_KEY not set in pivotlink.properties file: SSH_KEY = $SSH_KEY"
	echo "    Defaulting SSH_KEY to $HOME/.ssh/id_rsa-pivotlink"
	SSH_KEY=$HOME/.ssh/id_rsa-pivotlink
	echo "SSH_KEY=$HOME/.ssh/id_rsa-pivotlink" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ ! -f $SSH_KEY ]; then
	echo "** ERROR ** File not found in SSH_KEY from pivotlink.properties file: SSH_KEY = $SSH_KEY"
	exit 1
fi
if [ -z $SQL_DIR ]; then
	echo "** WARNING ** SQL_DIR not set in pivotlink.properties file: SQL_DIR = $SQL_DIR"
	echo "    Defaulting SQL_DIR to $HOME/sql"
	SQL_DIR=$HOME/sql
	echo "SQL_DIR=$HOME/sql" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ ! -d $SQL_DIR ]; then
	echo "** WARNING ** Directory not found SQL_DIR from pivotlink.properties file: SQL_DIR = $SQL_DIR"
	echo "    Creating direcory $SQL_DIR "
	if ! /bin/mkdir -p $SQL_DIR; then
		echo "** ERROR ** Unable to create SQL_DIR $SQL_DIR"
		exit 1
	fi
fi
if [ -z $SQL_FILE ]; then
	echo "** WARNING ** SQL_FILE not set in pivotlink.properties file: SQL_FILE = $SQL_FILE"
	echo "    Defaulting SQL_FILE to ${CUSTNAME}_analytics_daily.sql"
	SQL_FILE=${CUSTNAME}_analytics_daily.sql
	echo "SQL_FILE=${CUSTNAME}_analytics_daily.sql" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ ! -f ${SQL_DIR}/${SQL_FILE} ]; then
	echo "** ERROR ** File not found SQL_FILE from pivotlink.properties file: SQL_FILE = ${SQL_DIR}/${SQL_FILE}"
	exit 1
fi
if [ -z $ZIP_FILE ]; then
	echo "** WARNING ** ZIP_FILE not set in pivotlink.properties file: ZIP_FILE = $ZIP_FILE"
	echo "    Defaulting ZIP_FILE to ${CUSTNAME}_analytics_daily.zip"
	ZIP_FILE=${CUSTNAME}_analytics_daily.zip
	echo "ZIP_FILE=${CUSTNAME}_analytics_daily.zip" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $CHECKSUM_FILE ]; then
	echo "** WARNING ** CHECKSUM_FILE not set in pivotlink.properties file: CHECKSUM_FILE = $CHECKSUM_FILE"
	echo "    Defaulting CHECKSUM_FILE to checksum.analytics.daily"
	CHECKSUM_FILE=checksum.analytics.daily
	echo "CHECKSUM_FILE=checksum.analytics.daily" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $LOG_DIR ]; then
	echo "** WARNING ** LOG_DIR not set in pivotlink.properties file: LOG_DIR = $LOG_DIR"
	echo "    Defaulting LOG_DIR to $HOME/logs"
	LOG_DIR=$HOME/logs
	echo "LOG_DIR=$HOME/logs" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ ! -d $LOG_DIR ]; then
	echo "** WARNING ** Directory not found LOG_DIR from pivotlink.properties file: LOG_DIR = $LOG_DIR"
	echo "    Creating direcory $LOG_DIR "
	if ! /bin/mkdir -p $LOG_DIR; then
		echo "** ERROR ** Unable to create LOG_DIR $LOG_DIR"
		exit 1
	fi
fi
if [ -z $LOG_FILE ]; then
	echo "** WARNING ** LOG_FILE not set in pivotlink.properties file: LOG_FILE = $LOG_FILE"
	echo "    Defaulting LOG_FILE to ${CUSTNAME}_analytics_daily.log"
	LOG_FILE=${CUSTNAME}_analytics_daily.log
	echo "LOG_FILE=${CUSTNAME}_analytics_daily.log" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $ANALYTICS_DIR ]; then
	echo "** WARNING ** ANALYTICS_DIR not set in pivotlink.properties file: ANALYTICS_DIR = $ANALYTICS_DIR"
	echo "    Defaulting ANALYTICS_DIR to /u01/app/oradata/analytics"
	ANALYTICS_DIR=/u01/app/oradata/analytics
	echo "ANALYTICS_DIR=/u01/app/oradata/analytics" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ ! -e $ANALYTICS_DIR ]; then
	echo "** ERROR ** Directory not found ANALYTICS_DIR from pivotlink.properties file: ANALYTICS_DIR = $ANALYTICS_DIR"
	echo "    Plese set the ANALYTICS_DIR property or create the direcory $ANALYTICS_DIR"
	exit 1
fi
if [ -z $UPLOAD_HOST ]; then
	echo "** WARNING ** UPLOAD_HOST not set in pivotlink.properties file: UPLOAD_HOST = $UPLOAD_HOST"
	echo "    Defaulting UPLOAD_HOST to ${CUSTNAME}.upload.pivotlink.com ..."
	UPLOAD_HOST=${CUSTNAME}.upload.pivotlink.com
	echo "UPLOAD_HOST=${CUSTNAME}.upload.pivotlink.com" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $BATCH_SH ]; then
	echo "** WARNING ** BATCH_SH not set in pivotlink.properties file: BATCH_SH = $BATCH_SH"
	echo "    Defaulting BATCH_SH to ${CUSTNAME}_load.sh ..."
	BATCH_SH=${CUSTNAME}_load.sh
	echo "BATCH_SH=${CUSTNAME}_load.sh" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $EMAIL ]; then
	echo "** WARNING ** EMAIL not set in pivotlink.properties file: EMAIL = $EMAIL"
	echo "    Defaulting EMAIL to dba-team1-oncall-email@localhost ..."
	EMAIL=dba-team1-oncall-email@localhost
	echo "EMAIL=dba-team1-oncall-email@localhost" >> /u01/app/utils/pivotlink/pivotlink.properties
fi
if [ -z $ARCH_DAYS ]; then
	echo "** WARNING ** ARCH_DAYS not set in pivotlink.properties file: ARCH_DAYS = $ARCH_DAYS"
	echo "    Defaulting ARCH_DAYS to 10 days ..."
	ARCH_DAYS=10
	echo "ARCH_DAYS=10" >> /u01/app/utils/pivotlink/pivotlink.properties
fi


# Load $ORACLE_BIN, TMXCS
. $HOME/scripts/setupenv.sh




#----- Globals ----------------------------------------------------------------
RESULT=0
MD5SUM=$(which md5sum)
ISO_DATE=$(date +%Y%m%d-%H%M)
SSH_OPTIONS="-i $SSH_KEY -o StrictHostKeyChecking=no"
SCP_CMD="/usr/bin/scp $SSH_OPTIONS"
SSH_CMD="/usr/bin/ssh $SSH_OPTIONS"
ARCH_DIR=${ANALYTICS_DIR}/archive/daily/${ISO_DATE}




#----- main -------------------------------------------------------------------
# Check for the "TEST" command-line arg ...
if [ "x${1}" = "xTEST" ]; then
	TEST=true
fi



# Generate the analytics data.
echo "Daily analytics script started at " $(date)
START=$(date '+%s')

cd $SQL_DIR
echo "Entering SQL_DIR $SQL_DIR"
pwd

if [ $TEST ]; then 
	touch ${ANALYTICS_DIR}/${ZIP_FILE}
	RESULT=$?
else
	$ORACLE_BIN/sqlplus $TMXCS @${SQL_FILE}
	RESULT=$?
fi
if [ $RESULT -ne 0 ]; then
	msg="Daily analytics SQL script $SQL_FILE failed."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi

echo "Daily analytics script completed at " $(date)
END=$(date '+%s')

MIN=$(( ($END - $START) / 60 ))

echo "Analytitics processing took [$MIN] minutes to complete."

cd $ANALYTICS_DIR 
echo "Entering ANALYTICS_DIR $ANALYTICS_DIR"
pwd

if [ ! -f ${ANALYTICS_DIR}/${ZIP_FILE} ]; then
	msg="${ANALYTICS_DIR}/${ZIP_FILE} not found."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi

if [ ! -s ${ANALYTICS_DIR}/${ZIP_FILE} ]; then
	msg="${ANALYTICS_DIR}/${ZIP_FILE} size is zero bytes."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi

echo "Creating an md5 hash for validation ..."
echo $MD5SUM $ZIP_FILE > $CHECKSUM_FILE
if [ -z $TEST ]; then
	$MD5SUM $ZIP_FILE > $CHECKSUM_FILE
fi
if [ $? -ne 0 ]; then
	msg="Creation of $CHECKSUM_FILE failed."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi


echo "Sending the files to Pivotlink for processing:"
echo "SCP started at" `date`

echo "Upload the checksum ..."
echo $SCP_CMD $CHECKSUM_FILE ${CUSTNAME}@${UPLOAD_HOST}:${CHECKSUM_FILE}
if [ -z $TEST ]; then
	$SCP_CMD $CHECKSUM_FILE ${CUSTNAME}@${UPLOAD_HOST}:${CHECKSUM_FILE}
	RESULT=$?
fi
if [ $RESULT -ne 0 ]; then
	msg="SCP of $CHECKSUM_FILE failed."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi

echo "Upload the analytics data ..."
echo $SCP_CMD $ZIP_FILE ${CUSTNAME}@${UPLOAD_HOST}:${ZIP_FILE}
if [ -z $TEST ]; then
	$SCP_CMD $ZIP_FILE ${CUSTNAME}@${UPLOAD_HOST}:${ZIP_FILE}
	RESULT=$?
fi
if [ $RESULT -ne 0 ]; then
	msg="SCP of $ZIP_FILE failed."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" $NAGIOS_DATACENTER
	exit 1
fi

echo "SCP finished at " $(date)


echo "Starting the $BATCH_SH script" $(date)
[ $TEST ] && echo $SSH_CMD ${CUSTNAME}@${UPLOAD_HOST} "runbatch $BATCH_SH"
if [ -z $TEST ]; then
	$SSH_CMD ${CUSTNAME}@${UPLOAD_HOST} "runbatch $BATCH_SH"
	RESULT=$?
fi
if [ $RESULT -ne 0 ]; then
	msg="Script _load.sh failed to run via SSH."
	echo $msg
	/u01/app/utils/send_nsca_crit "Pivotlink Analytics [DBA PAGER]" "$msg" wdc
	exit 1
fi

echo "Load script $BATCH_SH finished at " $(date)

[ $TEST ] || /u01/app/utils/send_nsca_recovery "Pivotlink Analytics [DBA PAGER]" "SCP and Load to Pivotlink Successful|$MIN" $NAGIOS_DATACENTER
[ $TEST ] && /u01/app/utils/send_nsca_recovery "Pivotlink Analytics [DBA PAGER]" "Manual test of analytics_daily.sh script.|$MIN" $NAGIOS_DATACENTER


echo "Starting archive and clean up of working directory ..."
echo "Start archive " $(date)
if [ $TEST ]; then
	echo mkdir -pv                     $ARCH_DIR
	echo
	echo mv -v $ZIP_FILE               $ARCH_DIR
	echo
	echo mv -v $CHECKSUM_FILE          $ARCH_DIR
	echo
	echo cp -v ${LOG_DIR}/${LOG_FILE}  $ARCH_DIR
	echo
	echo rm -v *.txt *.log *.def *.rjt
else
	     mkdir -pv                     $ARCH_DIR
	     mv -v $ZIP_FILE               $ARCH_DIR
	     mv -v *.log                   $ARCH_DIR
	     mv -v *.def                   $ARCH_DIR
	     mv -v *.rjt                   $ARCH_DIR
	     mv -v $CHECKSUM_FILE          $ARCH_DIR
	     cp -v ${LOG_DIR}/${LOG_FILE}  $ARCH_DIR
	     rm -v *.txt *.log *.def *.rjt
fi

echo "Archiving finished at " $(date)


# Cleaning up 
echo "Cleaning up archives older than $ARCH_DAYS days ..." 
[ $TEST ] || find ${ANALYTICS_DIR}/archive/daily -type d -ctime +${ARCH_DAYS} | grep ".*daily/[[:digit:]]\{8\}-" | xargs rm -rf
[ $TEST ] && find ${ANALYTICS_DIR}/archive/daily -type d -ctime +${ARCH_DAYS} -ls | grep ".*daily/[[:digit:]]\{8\}-"


[ $TEST ] || cat ${LOG_DIR}/${LOG_FILE} | /u01/app/utils/mail.pl -s "$CUSTNAME Daily Analytics Log" $EMAIL
[ $TEST ] && echo "Email Subject: '$CUSTNAME Daily Analytics Log'  'To: $EMAIL'"

exit 0
