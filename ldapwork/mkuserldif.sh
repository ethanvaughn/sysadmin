#!/bin/bash

function usage_exit {
	echo
	echo "Creates an LDIF directed to STDOUT which will add a Posix user"
	echo "to the ldap database. The output is suitable for use with ldapadd."
	echo
	echo "Requires ./getnextuid.sh to be in cwd."
	echo
	echo "Usage: $0 login \"Full Name\" gid"
	echo
	echo "    gid: {101|60001} (dba or sysadmin) "
	echo "         Note: gid determines home directory:"
	echo "               101 = /u01/home/oracle"
	echo "             60001 = /u01/home/sysadmin"
	echo
	echo "eg."
	echo "$0 evaughn \"Ethan Vaughn\" 60001"
	echo 
	exit 1
}


if [ ! -x ./getnextuid.sh ]; then
	echo
	echo "-- FATAL --  Unable to execute the ./getnextuid.sh command. Please check cwd."
	usage_exit
fi

if [ $# -lt 3 ]; then 
	usage_exit
fi


username=$1
fullname=$2
gid=$3
homedir="oracle"
uid=$(./getnextuid.sh)

if [ "X${username}" = "X" ]; then
	echo
	echo "-- FATAL --  Missing username."
	usage_exit
fi

# This is just plain laziness: full name is required.
if [ "X${fullname}" = "X" ]; then
	echo
	echo "-- FATAL --  Missing Full Name."
	usage_exit
fi


if [ "X${gid}" = "X" ]; then
	echo
	echo "-- FATAL --  Missing Group ID."
	usage_exit
fi


if [ $gid = "60001" ]; then
	homedir=sysadmin
fi




# Look into expiring
# like the cvsuseradd.sh stuff...
cat <<-EOL 
	dn: uid=${username},ou=People,dc=tomax,dc=com
	uid: ${username}
	cn: ${username}
	objectClass: account
	objectClass: posixAccount
	objectClass: top
	objectClass: shadowAccount
	userPassword: ${username}
	uidNumber: ${uid}
	shadowLastChange: 12474
	shadowMax: 99999
	shadowWarning: 7
	loginShell: /bin/bash
	gidNumber: ${gid}
	homeDirectory: /u01/home/${homedir}
	gecos: ${fullname}
EOL

