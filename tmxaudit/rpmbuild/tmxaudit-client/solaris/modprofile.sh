#!/bin/bash

PROFILE=/etc/profile
TMP=/tmp/profile.tmxaudit

if (grep ".*tmxauditrc.*" $PROFILE); then
	sed "s/.*tmxaditrc.*/. \/etc\/tmxauditrc/" $PROFILE > $TMP
	mv $TMP $PROFILE
else
	/bin/echo ". /etc/tmxauditrc" >> /etc/profile
fi
