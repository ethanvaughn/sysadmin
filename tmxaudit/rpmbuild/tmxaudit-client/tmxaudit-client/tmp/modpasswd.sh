#!/bin/bash

# Seed the passwd, shadow, group files.

# Backup the files first:
cp /etc/passwd /etc/passwd.tmxaudit
cp /etc/shadow /etc/shadow.tmxaudit
cp /etc/group  /etc/group.tmxaudit


# Set the groups for the home dirs:
$(grep sysadmin /etc/group > /dev/null) || echo "sysadmin:x:40000:" >> /etc/group
$(grep dba      /etc/group > /dev/null) || echo "dba:x:101:"        >> /etc/group
$(grep syssup   /etc/group > /dev/null) || echo "syssup:x:40004:"   >> /etc/group
$(grep sysdev   /etc/group > /dev/null) || echo "sysdev:x:40003:"   >> /etc/group


exit 0
