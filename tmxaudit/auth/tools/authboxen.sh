#!/bin/sh

# List the IPs of the servers that have auth-client installed.
# We can easily gleen this info from /var/log/secure.

cat /var/log/secure | grep 'sshd.*tmxaudit'| cut -d " " -f11 | sort -u

