#!/bin/bash


#----- Globals ----------------------------------------------------------------
user=enterprisedb
uid=$(/u01/app/adminscripts/nextuid.pl)
appdir=/u01/app/postgres




#----- usage ------------------------------------------------------------------
function usage {
	echo 
	echo "Create the 'enterprisedb' user with password 'manager1'. The home directory"
	echo "is set to '/u01/home/edb' and the application directory is created at"
	echo "/u01/app/postgres."
	echo
	echo "Usage: $0"
	echo
}




#----- main -------------------------------------------------------------------
usage
read -p "Press ENTER to continue."

groupadd -g 108 edb

tmxuseradd -u $uid -g edb -c "EDB Postgres System Account" -d /u01/home/enterprisedb $user
if [ $? -ne 0  ]; then
	echo
	echo "*** ERROR *** See message above and take corrective action."
	echo
	exit 1
fi

echo "manager1" | passwd --stdin $user
mkdir $appdir
chown $user: $appdir
chmod g+rwxs $appdir

SUDO_CMD="%sysdba ALL=(ALL) NOPASSWD: /bin/su - $user"
echo "    $SUDO_CMD"
echo "$SUDO_CMD" >> /etc/sudoers

echo
echo "User $user Created with password 'manager1'."
echo 


echo "Check for required packages:"
echo
echo "bc"
yum -y install bc


echo
echo "libxml2"
yum -y install libxml2
yum -y install libxml2.i386
yum -y install libxml2.x86_64

echo
echo "libxslt"
yum -y install libxslt
yum -y install libxslt.i386
yum -y install libxslt.x86_64

echo
echo "expat"
yum -y install expat
yum -y install expat.i386
yum -y install expat.x86_64

echo
echo "libtiff"
yum -y install libtiff
yum -y install libtiff.i386
yum -y install libtiff.x86_64



exit 0
