#!/bin/bash

function usage_exit {
	echo
	echo "$0 link"
	echo
	exit 1
}




#---- main -------------------------------------------------------------------
ETHTOOL=$(which ethtool)

if [ ! -e $ETHTOOL ]; then
	echo "ethtool missing ..."
	exit 1
fi

LINKONLY=$1


ifconfig -a | grep eth | tr -s " " | cut -d" " -f1,5 | while read line; do
	DEV=$(echo $line|cut -d" " -f1)
	MAC=$(echo $line|cut -d" " -f2)
	LINKUP=$($ETHTOOL $DEV | grep -i 'link detected.*yes')
	if [ -n "$LINKUP" -o "X$LINKONLY" != "Xlink" ]; then 
		echo 
		echo [${MAC}]
		$ETHTOOL -i $DEV; 
		if [ -n "$LINKUP" ]; then
			echo "Link detected:       ** YES **"
		else
			echo "Link detected:       **  NO **"
		fi
	fi
done

echo
echo

exit 0
