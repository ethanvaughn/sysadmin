#!/bin/sh

# NTP Time Script

. /etc/TMXHOST.properties


NTP='/usr/sbin/ntpdate'
HWCLOCK='/sbin/hwclock'

if $NTP -u -b -s $NAGIOS_SERVER
then
  $HWCLOCK --systohc
fi

exit 0
