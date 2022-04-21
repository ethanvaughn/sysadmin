#!/bin/bash

HOSTS=/etc/inet/hosts
TMP=/tmp/hosts.tmxaudit

if (grep "127.*loghost.*" $HOSTS); then
	sed "s/127.*loghost.*/127.0.0.1        localhost/" $HOSTS > $TMP
	mv $TMP $HOSTS 
fi

if (grep ".*loghost.*" $HOSTS); then
	sed "s/.*loghost.*/10.24.74.13        loghost/" $HOSTS > $TMP
	mv $TMP $HOSTS 
else
	/bin/echo "10.24.74.13        loghost" >> $HOSTS
fi

