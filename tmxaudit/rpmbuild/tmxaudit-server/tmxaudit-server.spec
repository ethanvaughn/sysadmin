Summary: tmxaudit-server installer/updater
Name: tmxaudit-server
Version: 1.0.4
Release: 1
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
#BuildRequires: python
#BuildRequires: gettext
#Obsoletes: yum-phoebe
Requires: perl
Prereq: /sbin/chkconfig, /sbin/service

%description
TMXAUDIT server-side scripts and configs. This package does the following:

    o  Creates the /var/log/{messages.fifo,secure.fifo,cron.fifo} named pipes .
    o  Modifies /etc/syslog.conf to log messages to /var/log/messages.fifo
    o  Modifies /etc/syslog.conf to log authpriv to /var/log/secure.fifo
    o  Modifies /etc/syslog.conf to log cron to /var/log/cron.fifo 
    o  Installs the tmxauditlogd-secure daemon and initscript.
    o  Provides the /etc/cron.daily/tmxaudit script.


%prep
%setup



%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/cron.daily
%__mkdir_p $RPM_BUILD_ROOT/etc/init.d
%__mkdir_p $RPM_BUILD_ROOT/usr/sbin
%__mkdir_p $RPM_BUILD_ROOT/tmp
install -m 750 etc/init.d/tmxauditlogd-messages $RPM_BUILD_ROOT/etc/init.d/tmxauditlogd-messages
install -m 750 etc/init.d/tmxauditlogd-secure $RPM_BUILD_ROOT/etc/init.d/tmxauditlogd-secure
install -m 750 etc/init.d/tmxauditlogd-cron $RPM_BUILD_ROOT/etc/init.d/tmxauditlogd-cron
install -m 750 usr/sbin/tmxauditlogd-messages $RPM_BUILD_ROOT/usr/sbin/tmxauditlogd-messages
install -m 750 usr/sbin/tmxauditlogd-secure $RPM_BUILD_ROOT/usr/sbin/tmxauditlogd-secure
install -m 750 usr/sbin/tmxauditlogd-cron $RPM_BUILD_ROOT/usr/sbin/tmxauditlogd-cron
install -m 750 etc/cron.daily/tmxaudit $RPM_BUILD_ROOT/etc/cron.daily/tmxaudit
install -m 750 tmp/modconf.sh $RPM_BUILD_ROOT/tmp/modconf.sh


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)
%config /etc/init.d/tmxauditlogd-messages
%config /etc/init.d/tmxauditlogd-secure
%config /etc/init.d/tmxauditlogd-cron
/usr/sbin/tmxauditlogd-messages
/usr/sbin/tmxauditlogd-secure
/usr/sbin/tmxauditlogd-cron
%config /etc/cron.daily/tmxaudit
/tmp/modconf.sh


%post
# Make the required fifos
/usr/bin/mkfifo /var/log/messages.fifo
/usr/bin/mkfifo /var/log/secure.fifo
/usr/bin/mkfifo /var/log/cron.fifo
# Modify syslog.conf
/tmp/modconf.sh
# start up
/etc/init.d/tmxauditlogd-messages start
/etc/init.d/tmxauditlogd-secure start
/etc/init.d/tmxauditlogd-cron start
# restart syslog
/etc/init.d/syslog restart
# clean up
rm -f /tmp/modconf.sh
exit 0


%changelog
#date "+%a %b %d %Y"

* Wed Jun 07 2006 Ethan Vaughn
- 1.0.4-1
- Refactored tmxaudit-syslogd to tmxauditlogd-secure.
- Added services for cron and messages logs.
- Added modconf.sh to modify the syslog.conf file.


* Fri Jun 02 2006 Ethan Vaughn
- 1.0.3-1
- Removed the /etc/cron.daily/tmxaudit file.
- Created the /etc/init.d/tmxaudit-syslogd file.


