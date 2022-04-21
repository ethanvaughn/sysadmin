#!/bin/bash
         
if [ ! -f ./solsethomedir.sh ]; then
	echo ""
	echo "You must be in the install directory to run this script."
	echo ""
	exit 1
fi


echo "Updating /etc/hosts with loghost ..."
./modhosts.sh

echo "Updating /etc/syslog.conf ..."
./modconf.sh

#echo "Updating /etc/profile with ENV ..."
#(grep "ENV.*bashrc.*" /etc/profile) || /bin/echo "export ENV=$HOME/.bashrc" >> /etc/profile

echo "Updating /etc/profile with reference to /etc/tmxauditrc ..."
./modprofile.sh

#echo "Updating the sudoers file ..."
./solmodsudoers.pl

echo "Add the sshd user as a no-op placeholder ..."
mkdir -p /var/empty/sshd
groupadd -g 74 sshd
useradd -u 74 -g 74 -c "Privilege-separated SSH" -d /var/empty/sshd sshd



#echo "Installing the ssh keys ..."
#[ -d /root/.ssh ] || mkdir -p /root/.ssh
#chmod 600 /root/.ssh
#cp id_rsa /root/.ssh
#cp id_rsa.pub /root/.ssh
#chmod 600 /root/.ssh/id_rsa
#chmod 644 /root/.ssh/id_rsa.pub

echo "Installing etc files ..."
cp -f etc/tmxauditrc 		/etc/
cp -f etc/sudoers.tmxaudit 	/usr/local/etc/
cp -f etc/cron.d/* 			/etc/cron.d/
cp -f bash_profile          /etc/skel/.bash_profile
cp -f bashrc                /etc/skel/.bashrc

if [ ! -f /root/.bash_profile ]; then
	cp -f /etc/skel/.bash* /root
fi

echo "Installing authclient ..."
cp -rf auth-client/ /u01/app/
chmod +x /u01/app/auth-client/*
mkdir -p /u01/app/auth-client/work

echo "Installing adminscripts ..."
cp -rf adminscripts/ /u01/app/
chmod +x /u01/app/adminscripts/*
chmod o+r /u01/app/adminscripts/tmxaudit.properties

echo "Installing utils ..."
cp -rf utils/ /u01/app/
chmod +x /u01/app/utils/*
chmod o+r /u01/app/utils/*

echo "Locking down VNC binaries ..."
groupadd -g 250 vncusers
chgrp vncusers /usr/local/bin/*vnc*
chmod 550 /usr/local/bin/*vnc*


#echo "Initializing authentication files ..."
#/u01/app/auth-client/authclient.pl -i

# Make sure home directories are created and permissions are set:
#./solsethomedir.sh


# Restart syslog to enable remote logging:
#/etc/init.d/syslog restart


# Clean up 
#rm -f /tmp/id_rsa
#rm -f /tmp/id_rsa.pub
#rm -f /tmp/modconf.sh
#rm -f /tmp/solsethomedir.sh

echo "Done. Update the version flag ..."
cp ./tmxaudit.version /etc

# end of post-install script.
exit 0

