#!/bin/bash
#
# osupgrade.sh - Collect data prior to OS upgrade
#

ROOTDIR=/tmp
SUBDIR=osupgrade-output
OUTFILE=osupgrade.txt
DESTDIR=$ROOTDIR/$SUBDIR
DESTFILE=$DESTDIR/$OUTFILE

if [ $# -ne 1 ]; then
echo
	echo "Collect important OS settings and files prior to an OS upgrade"
	echo "This script will make tar copies of etc, var, boot and root"
	echo "Other parameters will be saved in $OUTFILE"
	echo "All of the data collected will be placed in $ROOTDIR/osupgrade.tgz"
	echo
	echo "Usage: $0 go"
	echo
	exit 1
fi

echo
echo
if [ ! -d $DESTDIR ]
then
	echo "Creating $DESTDIR"
	mkdir $DESTDIR
fi

# Capture important OS related files and settings 
echo "Creating etc.tar"
echo "Creating var.tar"
echo "Creating boot.tar"
echo "Creating root.tar"
echo "Creating usrlocalbin.tar"

CHECKLIST=(
"tar -cpf $DESTDIR/etc.tar /etc/"
"tar -cpf $DESTDIR/var.tar /var/"
"tar -cpf $DESTDIR/boot.tar /boot/"
"tar -cpf $DESTDIR/root.tar /root/"
"tar -cpf $DESTDIR/usrlocalbin.tar /usr/local/bin/"
"cat /etc/aliases"
"cat /etc/hosts"
"cat /etc/resolv.conf"
"cat /etc/sysconfig/network"
"cat /etc/sysconfig/network-scripts/ifcfg-eth0"
"cat /etc/sysconfig/network-scripts/ifcfg-eth1"
"cat /etc/sysconfig/network-scripts/ifcfg-eth2"
"cat /etc/sysconfig/network-scripts/ifcfg-eth3"
"cat /etc/sysconfig/network-scripts/ifcfg-eth4"
"cat /etc/sysconfig/network-scripts/ifcfg-eth5"
"cat /etc/sysconfig/network-scripts/ifcfg-eth6"
"cat /etc/sysconfig/network-scripts/ifcfg-eth7"
"cat /etc/sysconfig/network-scripts/ifcfg-eth8"
"cat /etc/modprobe.conf"
"cat /etc/modules.conf"
"cat /etc/iscsi.conf"
"cat /etc/initiatorname.iscsi"
"cat /etc/sysctl.conf"
"cat /etc/passwd"
"cat /etc/shadow"
"cat /etc/group"
"cat /etc/fstab"
"cat /etc/sudoers"
"cat /etc/bashrc"
"cat /var/spool/cron/root"
"cat /var/spool/cron/oas"
"cat /var/spool/cron/oracle"
"cat /var/spool/cron/nagios"
"cat /var/spool/cron/kmadmin"
"cat /var/spool/cron/csweetland"
"cat /var/spool/cron/apps"
"cat /var/spool/cron/lcao"
"cat /var/spool/cron/rdesanno"
"cat /etc/rc.d/rc.local"
"cat /etc/ssh/ssh_config"
"cat /etc/ssh/sshd_config"
"cat /etc/ssh/ssh_host_dsa_key"
"cat /etc/ssh/ssh_host_dsa_key.pub"
"cat /etc/ssh/ssh_host_key"
"cat /etc/ssh/ssh_host_key.pub"
"cat /etc/ssh/ssh_host_rsa_key"
"cat /etc/ssh/ssh_host_rsa_key.pub"
"cat /etc/grub.conf"
"cat /etc/redhat-release"
"cat /etc/sysconfig/vncservers"
"ls /etc/sysconfig/network-scripts" 
"ls -la /etc/sysconfig/network-scripts" 
"ifconfig -a"
"ls /var/spool/cron"
"df -h" 
"ls /etc/rc.d/rc3.d"
"rpm -qa"
"uname -a"
"chkconfig --list"
"ps -aux"
"netstat -tapn"
"sar"
"uptime"
"free -m"
"cat /proc/cpuinfo"
"ls -la /"
"ls -la /u01"
"ls -la /u02"
"cat /etc/TMXHOST.properties"
"cat /etc/postfix/main.cf"
"cat /etc/oraInst.loc"
"cat /etc/oratab"
"cat /usr/local/bin/coraenv"
"cat /usr/local/bin/dbhome"
"cat /usr/local/bin/oraenv"
"cat /usr/local/bin/set-env.sh"
"cat /usr/local/bin/set-env.sh"
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth0.PROD"
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth0.STBY"
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth1.PROD"
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth1.STBY" 
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth2.PROD" 
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth2.STBY" 
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth3.PROD"
"cat /etc/sysconfig/network-scripts/tomax/ifcfg-eth3.STBY"
) 

# Process $CHECKLIST and redirect to $DESTFILE
echo "Creating $OUTFILE"
echo >$DESTFILE
len=${#CHECKLIST[@]}
for (( i=0; i<${len}; i++ )); do
	echo "----------[${CHECKLIST[$i]}]--------------------">>$DESTFILE
	${CHECKLIST[$i]}>>$DESTFILE 2>&1
	echo >>$DESTFILE
done

# Get rid of tars and zip them up into one file
cd $DESTDIR
for i in *.tar; do tar xpf $i; done
rm *tar
cd $ROOTDIR
tar cpzf osupgrade.tgz osupgrade-output
rm -rf $DESTDIR

echo "DONE"
echo
echo "Files have been saved in $ROOTDIR/osupgrade.tgz"
echo
echo "***Copy osupgrade.tgz to a different server prior to the upgrade***"
echo
exit 0
