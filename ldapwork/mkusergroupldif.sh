#!/bin/bash

function usage_exit {
	echo
	echo "Creates an LDIF directed to STDOUT which will add a user to the"
	echo "specified LDAP group. The output is suitable for use with ldapmodify."
	echo
	echo "Usage: $0 group user"
	echo
	echo "    group: The ldap group name."
	echo "     user: The ldap user name."
	echo
	echo "eg."
	echo "$0 netuser evaughn"
	echo 
	exit 1
}


if [ $# -lt 2 ]; then 
	usage_exit
fi


user=$1
group=$2

if [ "X${user}" = "X" ]; then
	echo
	echo "-- FATAL --  Missing user."
	usage_exit
fi

if [ "X${group}" = "X" ]; then
	echo
	echo "-- FATAL --  Missing group."
	usage_exit
fi


cat <<-EOL 
	dn: cn=${user},ou=Group,dc=tomax,dc=com
	add: memberUid
	memberUid: ${group}
	-
EOL

