#!/bin/bash

function usage_exit {
	echo
	echo "Wrapper to create ldap user via ldapadd."
	echo
	echo "Requires the mkuserldif.sh and mkusergroupldif.sh commands in cwd."
	echo
	echo "Usage: $0 username \"Full Name\" gid"
	echo
	echo "    gid: {101|60001} (dba or sysadmin) "
	echo "         Note: gid determines home directory:"
	echo "               101 = /u01/home/oracle"
	echo "             60001 = /u01/home/sysadmin"
	echo
	echo "eg."
	echo "$0 evaughn \"Ethan Vaughn\" 60001"
	echo "$0 jrandom \"Jay Random\" 101"
	echo 
	exit 1
}

if [ $# -lt 3 ]; then 
	usage_exit
fi

username=$1
fullname="$2"
gid=$3

tmpfile=/tmp/$0.tmp

if [ ! -x ./mkuserldif.sh ]; then
	echo
	echo "-- FATAL -- Unable to execute the ./mkuserldif.sh command. Please check cwd."
	exit 1
fi
if [ ! -x ./mkusergroupldif.sh ]; then
	echo
	echo "-- FATAL -- Unable to execute the ./mkusergroupldif.sh command. Please check cwd."
	exit 1
fi

./mkuserldif.sh $username "$fullname" $gid > $tmpfile
ldapadd -x -D 'cn=manager,dc=tomax,dc=com' -w secret -f $tmpfile

# Add user to the "netuser" group.
# Create the modify ldif
./mkusergroupldif.sh netuser $username  > $tmpfile
ldapmodify -x -D 'cn=manager,dc=tomax,dc=com' -w secret -f $tmpfile
 
# Dispatch the email notification:
./send-reset-email.pl $username

