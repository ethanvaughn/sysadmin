#!/bin/bash

if [ "X$1" = "Xgenkey"  ]; then
	GENKEY=1
fi

ISD_UID=116
ISDSUPT_UID=117
TMXUSERADD="/usr/sbin/tmxuseradd"


HOME=/u01/home
APP=/u01/app

# Clean up any cruft ...
#tmxuserdel -r isd 2>/dev/null
#tmxuserdel -r isdsupt 2>/dev/null
#groupdel isd 2>/dev/null

# Check for isd users
EXISTS=0
EXISTS=`grep -e ^isd: /etc/passwd`

if [ -n "$EXISTS" ]
then
    MUID=`echo $EXISTS | cut -d ":" -f 3`
    echo "ISD User Already Exists UID=$MUID Normal UID=$ISD_UID"
else
    $TMXUSERADD -u $ISD_UID -c "ISD System Account" -d /u01/home/isd isd || exit 1
# Create the app directory.
    mkdir -p $APP/isd
    chown isd:isd /u01/app/isd
    chmod g+rwxs /u01/app/isd
# Do that sudo that you do so well.
    echo "%sysdba ALL =(ALL) NOPASSWD: /bin/su - isd" >> /etc/sudoers
    echo "%isd ALL =(ALL) NOPASSWD: /bin/su - isd" >> /etc/sudoers

fi


EXISTS=0
EXISTS=`grep -e ^isdsupt: /etc/passwd`

if [ -n "$EXISTS" ]
then
    MUID=`echo $EXISTS | cut -d ":" -f 3`
    echo "ISD User Already Exists UID=$MUID Normal UID=$ISDSUPT_UID"
else
# Add the accounts.
    $TMXUSERADD -u $ISDSUPD_UID -g $ISD_UID -c "ISD Support Login" -d /u01/home/isdsupt isdsupt || exit 1
    echo "isdsupt" | passwd --stdin isdsupt
    chage -M 3000 -d 113 isdsupt
fi

if [ $GENKEY ]; then
	# Gen SSH keys for the isduser
	su - isd -c "mkdir ~/.ssh" 
	su - isd -c "chmod 700 ~/.ssh"
	su - isd -c "ssh-keygen -t rsa -b 2048"
fi

exit 0
