#!/bin/bash

uid=$(/u01/app/adminscripts/nextuid.pl)

tmxuseradd -u $uid -c "Activant System Account" -d /u01/home/activant activant
/u01/app/adminscripts/groupappend.pl -u activant -g tomax

mkdir /u01/app/activant
chown activant:tomax /u01/app/activant
chmod g+rwxs /u01/app/activant
ln -s /u01/app/activant /activant

echo "Appending sudo access:"
SUDO_CMD="%sysdev,%sysdba ALL=(ALL) NOPASSWD: /bin/su - activant"
echo "    $SUDO_CMD"
echo "$SUDO_CMD" >> /etc/sudoers


echo "User activant Created."
echo 

echo "Setting up NFS access" 
echo "/activant *(rw,sync,no_root_squash)" >> /etc/exports 
chkconfig nfs on
service nfs restart

showmount -e localhost

exit 0
