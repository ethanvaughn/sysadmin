#!/bin/bash

function usage_exit {
	echo 
	echo "usage: $0 sourcename"
	echo
	echo "eg.  $0 DeltaCount"
	echo
	exit 1
}

if [ $# -ne 1 ]; then
	usage_exit
fi

SRC=$1

javac -cp . ServiceCheck.java 
if [ $? -ne 0 ]; then
	echo "ServiceCheck.java failed."
	exit 1
fi

cd ..
javac -cp lib:. Launcher.java
if [ $? -ne 0 ]; then
	echo "Launcher.java failed."
	exit 1
fi
cd - 

javac -cp ..:. $SRC.java
if [ $? -ne 0 ]; then
	echo "$SRC.java failed."
	exit 1
fi

#echo Deploying $SRC.class
#scp $SRC.class root@10.24.74.9:/u01/app/nagios/libexec/lib/

exit 0
