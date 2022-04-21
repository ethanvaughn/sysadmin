Summary: tmxaudit installer/updater
Name: tmxaudit-client
Version: 3.2.6
Release: 33
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
#BuildRequires: python
#BuildRequires: gettext
#Obsoletes: yum-phoebe
#Requires: pam, sudo
Requires: sudo, at
#Prereq: /sbin/chkconfig, /sbin/service

%description
TMXAUDIT scripts and configs:

    o Creates the /u01/home/sysadmin and /u01/home/sysdba home directories.
    o Sets correct ownership and group permissions on the home directories.
    o Overwrites the /etc/sudoers file preserving local changes.
	o Overwrites the /etc/tmxauditrc global config file.
	o Source the /etc/tmxauditrc from /etc/bashrc to log all commands for bash.
	o Adds remote syslog entries to the /etc/syslog.conf file.
	o Adds loghost entry into /etc/hosts.

This package is able to be updated when configs change with the "rpm -U" command.




%prep
%setup




%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/tmp
%__mkdir_p $RPM_BUILD_ROOT/etc/cron.d
#%__mkdir_p $RPM_BUILD_ROOT/etc/security
%__mkdir_p $RPM_BUILD_ROOT/usr/sbin
%__mkdir_p $RPM_BUILD_ROOT/u01/home/{sysdba,sysadmin}
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth-client/work
%__mkdir_p $RPM_BUILD_ROOT/u01/app/adminscripts
%__mkdir_p $RPM_BUILD_ROOT/u01/app/utils
%__mkdir_p $RPM_BUILD_ROOT/u01/app/utils/isd
%__mkdir_p $RPM_BUILD_ROOT/u01/app/utils/pivotlink
%__mkdir_p $RPM_BUILD_ROOT/u01/app/utils/revionics

install -m 770 tmp/modconf.sh    $RPM_BUILD_ROOT/tmp/modconf.sh
install -m 770 tmp/modpasswd.sh  $RPM_BUILD_ROOT/tmp/modpasswd.sh
install -m 770 tmp/modsudoers.pl $RPM_BUILD_ROOT/tmp/modsudoers.pl

install -m 600 ssh/id_rsa $RPM_BUILD_ROOT/tmp/id_rsa
install -m 644 ssh/id_rsa.pub $RPM_BUILD_ROOT/tmp/id_rsa.pub

install -m 644 etc/cron.d/authclient     $RPM_BUILD_ROOT/etc/cron.d/authclient
install -m 644 etc/cron.d/killvnc        $RPM_BUILD_ROOT/etc/cron.d/killvnc
install -m 644 etc/cron.d/timesync       $RPM_BUILD_ROOT/etc/cron.d/timesync
install -m 644 etc/cron.d/tmxaudit       $RPM_BUILD_ROOT/etc/cron.d/tmxaudit
install -m 644 etc/cron.d/tmxbu-agent    $RPM_BUILD_ROOT/etc/cron.d/tmxbu-agent
install -m 644 etc/tmxauditrc            $RPM_BUILD_ROOT/etc/tmxauditrc
#install -m 640 etc/security/access.conf.tmxaudit $RPM_BUILD_ROOT/etc/security/access.conf.tmxaudit

install -m 750 usr/sbin/useradd.tmxaudit $RPM_BUILD_ROOT/usr/sbin/useradd.tmxaudit
install -m 750 usr/sbin/userdel.tmxaudit $RPM_BUILD_ROOT/usr/sbin/userdel.tmxaudit
install -m 750 usr/sbin/usermod.tmxaudit $RPM_BUILD_ROOT/usr/sbin/usermod.tmxaudit

install -m 750 auth-client/ac.pm            $RPM_BUILD_ROOT/u01/app/auth-client/ac.pm
install -m 750 auth-client/authclient.pl    $RPM_BUILD_ROOT/u01/app/auth-client/authclient.pl
install -m 750 auth-client/backup.sh        $RPM_BUILD_ROOT/u01/app/auth-client/backup.sh
install -m 640 auth-client/conf.pm          $RPM_BUILD_ROOT/u01/app/auth-client/conf.pm
install -m 750 auth-client/notify-oncall.pl $RPM_BUILD_ROOT/u01/app/auth-client/notify-oncall.pl
install -m 770 auth-client/screenrc         $RPM_BUILD_ROOT/u01/app/auth-client/screenrc

install -m 770 adminscripts/addActivantUser.sh  $RPM_BUILD_ROOT/u01/app/adminscripts/addActivantUser.sh
install -m 770 adminscripts/addEdbUser.sh       $RPM_BUILD_ROOT/u01/app/adminscripts/addEdbUser.sh
install -m 770 adminscripts/addJBossUser.sh     $RPM_BUILD_ROOT/u01/app/adminscripts/addJBossUser.sh
install -m 770 adminscripts/addisd.sh           $RPM_BUILD_ROOT/u01/app/adminscripts/addisd.sh
install -m 770 adminscripts/addLocalUser.sh     $RPM_BUILD_ROOT/u01/app/adminscripts/addLocalUser.sh
install -m 770 adminscripts/addSystemUser.sh    $RPM_BUILD_ROOT/u01/app/adminscripts/addSystemUser.sh
install -m 770 adminscripts/bu.list             $RPM_BUILD_ROOT/u01/app/adminscripts/bu.list
install -m 770 adminscripts/grantRoot.sh        $RPM_BUILD_ROOT/u01/app/adminscripts/grantRoot.sh
install -m 770 adminscripts/grantSudo.sh        $RPM_BUILD_ROOT/u01/app/adminscripts/grantSudo.sh
install -m 770 adminscripts/groupappend.pl      $RPM_BUILD_ROOT/u01/app/adminscripts/groupappend.pl
install -m 770 adminscripts/killvnc.pl          $RPM_BUILD_ROOT/u01/app/adminscripts/killvnc.pl
install -m 770 adminscripts/nextuid.pl          $RPM_BUILD_ROOT/u01/app/adminscripts/nextuid.pl
install -m 770 adminscripts/revokeRoot.sh       $RPM_BUILD_ROOT/u01/app/adminscripts/revokeRoot.sh
install -m 770 adminscripts/revokeSudo.sh       $RPM_BUILD_ROOT/u01/app/adminscripts/revokeSudo.sh
install -m 770 adminscripts/rfprintfix.pl       $RPM_BUILD_ROOT/u01/app/adminscripts/rfprintfix.pl
install -m 770 adminscripts/rotate.sh           $RPM_BUILD_ROOT/u01/app/adminscripts/rotate.sh
install -m 770 adminscripts/timesync.sh         $RPM_BUILD_ROOT/u01/app/adminscripts/timesync.sh
install -m 770 adminscripts/tmxbu-agent.sh      $RPM_BUILD_ROOT/u01/app/adminscripts/tmxbu-agent.sh
install -m 770 adminscripts/trim.awk            $RPM_BUILD_ROOT/u01/app/adminscripts/trim.awk

install -m 755 utils/file-reaper.sh             $RPM_BUILD_ROOT/u01/app/utils/file-reaper.sh
install -m 755 utils/lcase.sh                   $RPM_BUILD_ROOT/u01/app/utils/lcase.sh
install -m 755 utils/mail.pl                    $RPM_BUILD_ROOT/u01/app/utils/mail.pl
install -m 755 utils/nagios-notify.pl           $RPM_BUILD_ROOT/u01/app/utils/nagios-notify.pl
install -m 755 utils/nagoff.sh                  $RPM_BUILD_ROOT/u01/app/utils/nagoff.sh
install -m 755 utils/nagon.sh                   $RPM_BUILD_ROOT/u01/app/utils/nagon.sh
install -m 755 utils/sar-cpu-csv.sh             $RPM_BUILD_ROOT/u01/app/utils/sar-cpu-csv.sh
install -m 755 utils/srm.sh                     $RPM_BUILD_ROOT/u01/app/utils/srm.sh
install -m 755 utils/utils.pm                   $RPM_BUILD_ROOT/u01/app/utils/utils.pm

install -m 755 utils/isd/reset-settlement-status.sh    $RPM_BUILD_ROOT/u01/app/utils/isd/reset-settlement-status.sh

install -m 755 utils/pivotlink/analytics_daily.sh      $RPM_BUILD_ROOT/u01/app/utils/pivotlink/analytics_daily.sh
install -m 755 utils/pivotlink/reset-nagios-service.sh $RPM_BUILD_ROOT/u01/app/utils/pivotlink/reset-nagios-service.sh

install -m 755 utils/revionics/revionics.sh     $RPM_BUILD_ROOT/u01/app/utils/revionics/revionics.sh


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT




%pre
echo
echo "begin pre"
echo "These aren't the droids we're looking for."
echo "Move along."
echo "end pre"
echo
exit 0




%files
%defattr(-, root, root)

/tmp/modconf.sh
/tmp/modpasswd.sh
/tmp/modsudoers.pl
/tmp/id_rsa
/tmp/id_rsa.pub

/etc/cron.d/authclient
%config /etc/cron.d/killvnc
/etc/cron.d/timesync
/etc/cron.d/tmxbu-agent
/etc/cron.d/tmxaudit
%config /etc/tmxauditrc
#%config /etc/security/access.conf.tmxaudit

/usr/sbin/useradd.tmxaudit
/usr/sbin/userdel.tmxaudit
/usr/sbin/usermod.tmxaudit

/u01/app/auth-client/ac.pm
/u01/app/auth-client/authclient.pl
/u01/app/auth-client/backup.sh
%config /u01/app/auth-client/conf.pm
/u01/app/auth-client/notify-oncall.pl
/u01/app/auth-client/screenrc

/u01/app/auth-client/work

/u01/app/adminscripts/addActivantUser.sh
/u01/app/adminscripts/addEdbUser.sh
/u01/app/adminscripts/addJBossUser.sh
/u01/app/adminscripts/addisd.sh
/u01/app/adminscripts/addLocalUser.sh
/u01/app/adminscripts/addSystemUser.sh
/u01/app/adminscripts/bu.list
/u01/app/adminscripts/grantRoot.sh
/u01/app/adminscripts/grantSudo.sh
/u01/app/adminscripts/groupappend.pl
/u01/app/adminscripts/killvnc.pl
/u01/app/adminscripts/nextuid.pl
/u01/app/adminscripts/revokeRoot.sh
/u01/app/adminscripts/revokeSudo.sh
/u01/app/adminscripts/rfprintfix.pl
/u01/app/adminscripts/rotate.sh
/u01/app/adminscripts/timesync.sh
/u01/app/adminscripts/tmxbu-agent.sh
/u01/app/adminscripts/trim.awk

/u01/app/utils/file-reaper.sh
/u01/app/utils/lcase.sh
/u01/app/utils/mail.pl
/u01/app/utils/nagios-notify.pl
/u01/app/utils/nagoff.sh
/u01/app/utils/nagon.sh
/u01/app/utils/sar-cpu-csv.sh
/u01/app/utils/srm.sh
/u01/app/utils/utils.pm

/u01/app/utils/isd/reset-settlement-status.sh

/u01/app/utils/pivotlink/analytics_daily.sh
/u01/app/utils/pivotlink/reset-nagios-service.sh

/u01/app/utils/revionics/revionics.sh



%post
echo "Updating /etc/sudoers . . . "
/tmp/modsudoers.pl

echo "Updating /etc/syslog.conf . . . "
/tmp/modconf.sh

echo "Updating /etc/hosts with loghost . . . "
(grep -q ".*loghost.*" /etc/hosts) || /bin/echo "10.24.74.13        loghost" >> /etc/hosts && sed -i "s/.*loghost.*/10.24.74.13        loghost/" /etc/hosts;

echo "Update known_hosts with loghost ssh host-key . . ."
(grep -q ".*loghost.*" /root/.ssh/known_hosts) || echo "loghost,10.24.74.13 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA32BGWTPwCZuUQKkiUSOwhLl9v2kqDThe/O8FTO9j0MEJ7G0XCxFBhWeb4akmInivIoGTL+RUjoDXybHBGmgTzY5sv2IkDbJVXc6D+EMjTgS6yDSd7wIWSsXCMUPfw0nVvMYplCi8UyTQ4KkcnECEE72e15XVQgbpSW/HdvCfUCU=" >> /root/.ssh/known_hosts

echo "Revoking direct root login within /etc/ssh/sshd_config . . . "
(grep -q ".*PermitRootLogin.*" /etc/ssh/sshd_config) || /bin/echo "PermitRootLogin no" >> /etc/ssh/sshd_config && sed -i "s/.*PermitRootLogin.*/PermitRootLogin no/" /etc/ssh/sshd_config;
/etc/init.d/sshd reload

echo "Removing gpgcheck in /etc/yum.conf for rh5 servers . . . "
(grep -q "release 5" /etc/issue) && sed -i "s/.*gpgcheck.*//" /etc/yum.conf

echo "Removing 'requiretty' from sudoers . . . "
(grep -q "^Defaults.*requiretty" /etc/sudoers) && sed -i "s/^Defaults.*requiretty/#Defaults  requiretty/" /etc/sudoers

echo "Updating /etc/bashrc with reference to /etc/tmxauditrc . . . "
(grep -q ".*tmxauditrc.*" /etc/bashrc) || /bin/echo ". /etc/tmxauditrc" >> /etc/bashrc && sed -i "s/.*tmxauditrc.*/. \/etc\/tmxauditrc/" /etc/bashrc;

echo "Settig umask in /etc/bashrc . . . "
(grep -q "^umask" /etc/bashrc) || /bin/echo "umask 002" >> /etc/bashrc && sed -i "s/^umask.*/umask 002/" /etc/bashrc;

echo "Installing the ssh keys ..."
[ -d /root/.ssh ] || mkdir -p /root/.ssh
chmod 600 /root/.ssh
cp /tmp/id_rsa /root/.ssh
cp /tmp/id_rsa.pub /root/.ssh
chmod 600 /root/.ssh/id_rsa
chmod 644 /root/.ssh/id_rsa.pub

echo "Initializing authentication files ..."
/tmp/modpasswd.sh

echo "Setting permissions for the config files ... "
%__chmod 440 /etc/sudoers
#cp -f /etc/security/access.conf /etc/security/access.conf.bak
#cp -f /etc/security/access.conf.tmxaudit /etc/security/access.conf

echo "Locking down useradd, userdel, usermod commands ..."
if [ ! -f /usr/sbin/tmxuseradd ]; then
	if (grep -q "ELF" /usr/sbin/useradd); then
		mv /usr/sbin/useradd /usr/sbin/tmxuseradd
		cp -f /usr/sbin/useradd.tmxaudit /usr/sbin/useradd
	fi
fi
if [ ! -f /usr/sbin/tmxuserdel ]; then
	if (grep -q "ELF" /usr/sbin/userdel); then
		mv /usr/sbin/userdel /usr/sbin/tmxuserdel
		cp -f /usr/sbin/userdel.tmxaudit /usr/sbin/userdel
	fi
fi
if [ ! -f /usr/sbin/tmxusermod ]; then
	if (grep -q "ELF" /usr/sbin/usermod); then
		mv /usr/sbin/usermod /usr/sbin/tmxusermod
		cp -f /usr/sbin/usermod.tmxaudit /usr/sbin/usermod
	fi
fi

echo "Setting adminscripts permissions ..."
%__chmod -R g+rwxs /u01/app/adminscripts
%__chgrp -R sysadmin /u01/app/adminscripts

echo "Setting utils permissions ..."
find /u01/app/utils -type d | xargs %__chmod g+rwxs
%__chgrp -R dba /u01/app/utils

echo "Locking down the VNC binaries ..."
groupadd -g 250 vncusers
chgrp vncusers /usr/bin/vnc* /usr/bin/Xvnc
chmod 750 /usr/bin/vnc* /usr/bin/Xvnc

echo "Restarting syslog to enable remote logging ..."
/etc/init.d/syslog restart


# Clean up 
rm -f /tmp/id_rsa
rm -f /tmp/id_rsa.pub
rm -f /tmp/modconf.sh
rm -f /tmp/modpasswd.sh
rm -f /tmp/modsudoers.pl

# end of post-install script.
exit 0




%changelog
#date "+%a %b %d %Y"

* Tue May 04 2010 Ethan Vaughn
- 3.2.6-33
- Fixed rogue exit in /u01/app/adminscripts/rfprinterfix.place

* Tue Apr 27 2010 Ethan Vaughn
- 3.2.6-32
- Modified utils/pivotlink/analytics_daily.sh to save *.log, *.rjt, etc in the archive dir.

* Tue Mar 30 2010 Ethan Vaughn
- 3.2.6-30
- Fixed problem with utils/pivotlink/analytics_daily.sh to clean up the archive dir.

* Fri Mar 16 2010 Ethan Vaughn
- 3.2.6-28
- Modified addEdbUser.sh set homedir to /u01/app/enterprisedb rather than edb.

* Fri Mar 16 2010 Ethan Vaughn
- 3.2.6-27
- Modified addJBOSSUser to add the user to the tomax group.

* Fri Jan 15 2010 Ethan Vaughn
- 3.2.6-26
- Modified pivotlink_daily.sh to remove .txt files since they are in 
  the .zip already.

* Tue Aug 17 2009 Ethan Vaughn
- 3.2.6-25
- Fixed killvnc.pl to remove sessions for non-existent accounts.

* Tue Aug 17 2009 Ethan Vaughn
- 3.2.6-24
- Added utils/revionics/revionics.sh

* Tue Aug 04 2009 Ethan Vaughn
- 3.2.6-22
- Modified archival of pivotlink: archive the .txt and add hours/min to the
  timestamp of the archive dir.

* Mon Aug 03 2009 Ethan Vaughn
- 3.2.6-20
- Added further checks in pivotlink file for checksum creation, zero byte
  zip file, etc. 
- Added cups management scripts in adminscripts.


* Tue Jul 28 2009 Ethan Vaughn
- 3.2.6-19
- Removed the debug lines from the pivotlink/analytics_daily.sh log.
- Added metric count of time to complete the processing for pivotlink. 

* Mon Jul 27 2009 Ethan Vaughn
- 3.2.6-17
- Added utils/srm.sh
- Updated pivotlink/analytics_daily.sh

* Tue Jul 08 2009 Ethan Vaughn
- 3.2.6-16
- Added addActivantUser.sh to adminscripts
- Added utils/pivotlink/reset-nagios-service.sh

* Tue Jul 06 2009 Ethan Vaughn
- 3.2.6-13
- Debug and deployment of utils/pivotlink/analytics_daily.sh

* Tue Jun 30 2009 Ethan Vaughn
- 3.2.6-9
- Added utils/utils.pm
- Modified utils/mail.pl to use TMXHost.properties
- Modified utils/nagios-notify.pl to use utils.pm
- Added utils/pivotlink/analytics_daily.sh

* Wed Jun 17 2009 Ethan Vaughn
- 3.2.6-7
- added /u01/app/utils/isd/reset-settlement-status.sh

* Wed Jun 17 2009 Ethan Vaughn
- 3.2.6-6
- Moved timesync.sh to /u01/adminscripts
- Added the -b option to timesync.sh 
- Modified /etc/cron.d/timesync to call /u01/adminscripts/timesync.sh

* Tue Jun 16 2009 Ethan Vaughn
- 3.2.6-3
- Added utils/timesync.sh and adminscripts/addSystemUser.sh

* Fri Jun 12 2009 Ethan Vaughn
- 3.2.6-2
- /u01/app/adminscripts/tmxaudit.properties is no more! This functionality
  has been removed from this RPM and will be handled manually during host
  loadout in the /etc/TMXHOST.properties file.
- Modified adminscripts/killvnc.pl and utils/nogios-notify.pl to use 
  TXMHOST.properties rather than tmxaudit.properties

* Fri Jun 12 2009 Ethan Vaughn
- 3.2.5-32
- Remove 'Defaults requiretty' from /etc/sudoers.

* Wed Jun 10 2009 Ethan Vaughn
- 3.2.5-31
- Added nagoff/nagon to /utils
- Set permissions on tmxaudit.properties
- Change gpgcheck=1 to 0 in /etc/yum.conf

* Thu Jun 06 2009 Ethan Vaughn
- 3.2.5-30
- Added nagios-notify.pl to /utils
- Modified permissions on /utils to be world exec.

* Thu May 21 2009 Ethan Vaughn
- 3.2.5-28
- Fixed bug in authclient: removed the -R from chown that was causing
  symlink target to get set to the user permissions.

* Thu Apr 24 2009 Ethan Vaughn
- 3.2.5-27
- Added the addEdbUser.sh to adminscripts. 
- Removed password rotation from addLocalUser.sh accounts.
- Fixed umask in /etc/bashrc to allow root to create group-read files. 

* Mon Dec 03 2008 Ethan Vaughn
- 3.2.5-25
- Changed kill cron to 7am and to run only on Sat.

* Mon Nov 30 2008 Ethan Vaughn
- 3.2.5-24
- Changed kill cron to 7am.
- Set default KILLVNC to "yes" in tmxaudit.properties file.

* Fri Nov 28 2008 Ethan Vaughn
- 3.2.5-23
- Added killvnc script and cron.
- Added adminscripts/tmxaudit.properties file.

* Mon Nov 17 2008 Ethan Vaughn
- 3.2.5-22
- Added a check to the known-hosts the loghost host-key so we do not end up 
  spamming the file. 
- Added the ssh-key for the tmxaudit account on the loghost box. This got
  disabled with version 3.2.5-15 when the tmxaudit local user was removed.

* Mon Nov 14 2008 Ethan Vaughn
- 3.2.5-20
- Set the loghost ssh host-key into the .ssh/known-hosts so the tmxbu-agent 
  will work.

* Mon Nov 10 2008 Ethan Vaughn
- 3.2.5-19
- Removed the tmxaudit account from sudoers.
- Removed the 5 "standard" JBoss accounts from sudoers (apparently they
  are not standard).
- Modified addJBossUser.sh script in adminscripts to append sudoers access
  for the sysdba and sysdev groups.

* Thu Jul 17 2008 Ethan Vaughn
- 3.2.5-18
- Added the ftpdl accounts to default sudoers.

* Thu Jul 17 2008 Ethan Vaughn
- 3.2.5-17
- Added the 5 standard jboss accounts to default sudoers.
- Modified addJBossUser.pl to reflect the change.

* Mon Jun 23 2008 Ethan Vaughn
- 3.2.5-15
- Fixed bug in the addLocalUser.sh script.
- Added adminscripts to PATH.
- Removed the ssh keys that are no longer used for nightly update.
- Removed tmxaudit user from the list of key accounts in authclient.
- User root to be controlled centrally.
- Authclient now cleans up any crufty files and dirs from the group-home dirs.
- Added PermitRootLogin=no to default policies to disallow root logins. 

* Thu Jun 05 2008 Ethan Vaughn
- 3.2.5-13
- Changed the name of the trap DEBUG function.
- Changed the $cmd variable in the /etc/tmxauditrc to $tmxcmd to avoid conflicts
  with the domino install scripts (and other possible conflicts).

* Tue May 30 2008 Ethan Vaughn
- 3.2.5-11
- Fixed homedir in AddLocalUser.sh

* Tue May 23 2008 Ethan Vaughn
- 3.2.5-10
- Added new scripts grantSudo.sh, revokeSudo.sh, AddLocalUser.sh

* Tue Apr 29 2008 Ethan Vaughn
- 3.2.5-9
- Fixed bug in nextuid.pl

* Tue Apr 29 2008 Ethan Vaughn
- 3.2.5-8
- Added screenrc file to the authclient project. It will be distributed during 
  nightly authclient checks.
- Update all user .bash_profile configs during authclient checks to allow sharing 
  of screen sessions.
- Make sure all users have a .bash_profile in their home dir.

* Wed Apr 02 2008 Ethan Vaughn
- 3.2.5-1
- No more paging. Alert via email only.
- Added setDefaultPolicies function.

* Wed Mar 19 2008 Ethan Vaughn
- 3.2.4-12
- Added adminscripts/addisd.sh
- Added setHomeDir function to create and remove account home dirs.
- Removed the .tmxauditrc files.
- Removed the /tmp/sethomedir.sh

* Tue Mar 05 2008 Ethan Vaughn
- 3.2.3-8
- Added adminscripts/nexuid.pl and utils/file-reaper.sh.
- Added adminscripts/addJBossUser.
- Purge the "export ENV" line from the /etc/profile that we had set earlier while trying to 
  get the ksh to work with the command logging.

* Wed Feb 06 2008 Ethan Vaughn
- 3.2.2-1
- Moved adminscripts and utils to top-level projects, then included them here.

* Fri Jan 04 2008 Ethan Vaughn
- 3.2.0-4
- Fixed the password in the shadow file for the tmxaudit user.

* Wed Dec 19 2007 Ethan Vaughn
- 3.2.0-3
- Modified grant/revokeRoot.sh to take user name.
- Removed the dba group root access from the stock sudoers.
- Added modpasswd.pl for initial install.
- The auth-client.pl script is no longer called on initial install.
- Added the tmxaudit /etc/cron.d script to run "yum -y update tmxaudit-client" daily.


* Mon Sep 24 2007 Ethan Vaughn
- 3.1.4-14
- Added nextuid.pl to the adminscripts utilities.

* Fri Sep 14 2007 Ethan Vaughn
- 3.1.4-13
- Modified auth-client to use Perl Net::FTP rather than a shell call to scp.

* Thu Aug 01 2007 Ethan Vaughn
- 3.1.4-9
- Added the groupappend command.
- Removed grant/revokeVNC.sh commands.
- Added timeout and retry to the authclient.

* Thu Jun 28 2007 Ethan Vaughn
- 3.1.4-6
- Added grant/revokeVNC.sh commands.
- Modify permissions on the vncserver and Xvnc system commands to allow
  access only to users in the "vncusers" group.

* Thu Apr 19 2007 Ethan Vaughn
- 3.1.4-2
- Added the user* commands to replace the system useradd, usermod, and 
- userdel with placeholders that remind the user to use central management.

* Thu Apr 05 2007 Ethan Vaughn
- 3.1.3-1
- Added grantRoot.sh and revokeRoot.sh to supercede the tmxrevoke.sh script.

* Wed Jan 17 2007 Ethan Vaughn
- 3.1.2-6
- Added modsudoers.pl file.
- Removed /etc/sudoers.tmxaudit file.
- Added syssup group and home directory.


* Tue Dec 12 2006 Ethan Vaughn
- 3.1.1-3
- Added sysdev group.
- Removed root, dba, jboss groups from central db.
- RPM dep on atd.
- Added du to dba sudoers group.


* Fri Dec 08 2006 Ethan Vaughn
- 3.0.2-5
- Moved the scripts from /usr/sbin to /u01/app/adminscripts
- Added tmxbu-agent.sh

* Thu Nov 16 2006 Ethan Vuaghn
- 3.0.1-11
- Fixed sudoers file to use dba group rather than deprecated sysdba.
- Added the /usr/sbin/tmxrevoke.sh script to expire dba group root access.

* Wed Oct 25 2006 Ethan Vaughn
- 3.0.1-10
- Removed the getlocal scripts since the functions have been moved to lib.
- getLocalGroup modified to default to the remote group when groups conflict
  between local and remote.
- Added chown to the sudoers
- Changed sudoers to use the 'dba' group rather than the deprecated sysdba.
- Removed sysdba group from the keygroups verification list.

* Thu Oct 19 2006 Ethan Vaughn
- 3.0.1-7
- Added notes,notesdev,notestest users to sudoers file.
- Removed tomax, oracle, oas from 'key accounts' list used for sanity checks.
- Modified /u01/home/sysdba to be setgid dba group (local group 101).

* Fri Sep 29 2006 Ethan Vaughn
- 3.0.1-5
- Added notify-oncall.pl to authclient and enabled notifications.


* Tue Sep 26 2006 Ethan Vaughn
- 3.0.1-3
- TFD rewrite of authclient.


* Thu Aug 17 2006 Ethan Vaughn
- 3.0.0-18
- Refactored to install to /u01/app/ instead of /opt/
- Moved home dir creation to a helper script: sethomedir.sh


* Tue Aug 15 2006 Ethan Vaughn
- 3.0.0-8
- Brand new sudoers.
- Add the authclient.pl to root's cron on 5 min interval.


* Mon Jul 24 2006 Ethan Vaughn
- 3.0.0-7
- Initialize auth files prior to setting permissions.


* Fri Jul 21 2006 Ethan Vaughn
- 3.0.0-6
- Added hostname normalization.
- Set HOST to "loghost" in conf.pm


* Mon Jul 17 2006 Ethan Vaughn
- 3.0.0-4
- Added clean up to the authclient. 
- Modified dba users to use the centrally-managed "sysdba" group rather 
  than the local "dba" group.


* Fri Jun 30 2006 Ethan Vaughn
- 3.0.0-1
- Added auth-client project.


* Wed Jun 28 2006 Ethan Vaughn
- 2.0.2-1
- Added ssh keys.


* Thu Jun 08 2006 Ethan Vaughn
- 2.0.1-2
- Added support for messages and cron.
- Added /tmp/modconf.sh


* Fri Jun 02 2006 Ethan Vaughn
- 2.0.0-2
- Changed loghost from .9 to .13 in the /etc/hosts.


* Wed May 10 2006 Ethan Vaughn
- 2.0.0-1
- Complete rewrite of the tmxaudit package since we are no longer using LDAP
  for auth, etc. 


* Fri Feb 03 2006 Ethan Vaughn
- 1.0.4-2
- Added modification of the syslog.conf for the remote syslogging (thus
  removing yet another manual step from the initial setup).


* Fri Feb 03 2006 Ethan Vaughn
- 1.0.4-1
- Refactored to use nested source directories.
- Added the commented hooks for the tmxaudit-clientd and tmxaudit-psacctd
  daemons and init scripts. These will be uncommented with they are avail.
- Modified sudoers and access.conf to be sudoers.tmxaudit and
  access.conf.tmxaudit so they don't conflict with the config files of the
  sudo and the pam packages. This eliminates the need for the use of
  the --force parameter with the "rpm" command. The post script herein will
  simply backup current config file and overwrite it our .tmxaudit version.


* Thu Feb 02 2006 Ethan Vaughn
- 1.0.3-1
- Modified .tmxauditrc to only do the XAUTHORITY foolery if the user is a
  member of the "netuser" ldap group. Otherwise it needs to skip it in
  in order to preserve the ldap user's XAUTHORITY (which is the whole
  purpose of the XAUTHORITY foolery in the first place).


* Wed Feb 01 2006 Ethan Vaughn
- 1.0.2-2
- Added taldap entry to the /etc/hosts file.
- Fixed all "grep > /dev/null" to use "grep -q".


* Fri Jan 13 2006 Ethan Vaughn
- 1.0.2-1
- Create a bu of .bash_profile -> .bash_profile.bak file.
- Ensure all subdirs of home/{oracle,sysadmin} are setgid.
- Modified .tmxauditrc to set umask 002.


* Tue Jan 10 2006 Ethan Vaughn
- 1.0.1-3
- Ownership and permissions (esp. .bash*, /etc/sudoers, .ssh/known_hosts).


* Tue Jan 10 2006 Ethan Vaughn
- 1.0.1-2
- Fixed bug with update overwriting ~/.bash* local config files. It is
  extrememly important that these file are not overwritten if they
  already exist.


* Thu Jan 05 2006 Ethan Vaughn
- 1.0.1-1

