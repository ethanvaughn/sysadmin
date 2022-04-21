#!/bin/bash

# Search the ldap users and return the next sequential UID.
# Todo: search for empty numbers. Ick. 

declare -i lastuid=$(ldapsearch -x -LLL '(objectClass=account)' uidNumber | grep uidNumber | cut -d " " -f 2 | sort | tail -n 1)

echo $[ $lastuid + 1 ];
