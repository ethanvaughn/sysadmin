Summary: nquery installer/updater
Name: nquery
Version: 1.0.3
Release: 7
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
#BuildRequires: python
#BuildRequires: gettext
#Obsoletes: yum-phoebe
Requires: perl
#Prereq: /sbin/chkconfig, /sbin/service

%description
nQuery is a Perl CGI HTTP-RPC API for querying the Nagios config files.


%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/nquery/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/nquery/lib

install -m 644 nquery.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/nquery.conf

install -m 755 cgi/listcusts $RPM_BUILD_ROOT/u01/app/nquery/cgi/listcusts
install -m 755 cgi/listhosts $RPM_BUILD_ROOT/u01/app/nquery/cgi/listhosts
install -m 755 cgi/listenv $RPM_BUILD_ROOT/u01/app/nquery/cgi/listenv
install -m 755 cgi/listtypes $RPM_BUILD_ROOT/u01/app/nquery/cgi/listtypes
install -m 755 cgi/listhoststat $RPM_BUILD_ROOT/u01/app/nquery/cgi/listhoststat
install -m 755 cgi/liststatcsv $RPM_BUILD_ROOT/u01/app/nquery/cgi/liststatcsv
install -m 755 cgi/listunack $RPM_BUILD_ROOT/u01/app/nquery/cgi/listunack

install -m 644 lib/hostgroup.pm $RPM_BUILD_ROOT/u01/app/nquery/lib/hostgroup.pm
install -m 644 lib/objectcache.pm $RPM_BUILD_ROOT/u01/app/nquery/lib/objectcache.pm
install -m 644 lib/nqcommon.pm   $RPM_BUILD_ROOT/u01/app/nquery/lib/nqcommon.pm
install -m 644 lib/statusdat.pm $RPM_BUILD_ROOT/u01/app/nquery/lib/statusdat.pm

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

%config /etc/httpd/conf.d/nquery.conf

/u01/app/nquery/cgi/listcusts
/u01/app/nquery/cgi/listhosts
/u01/app/nquery/cgi/listenv
/u01/app/nquery/cgi/listtypes
/u01/app/nquery/cgi/listhoststat
/u01/app/nquery/cgi/liststatcsv
/u01/app/nquery/cgi/listunack


/u01/app/nquery/lib/hostgroup.pm
/u01/app/nquery/lib/objectcache.pm
/u01/app/nquery/lib/nqcommon.pm
/u01/app/nquery/lib/statusdat.pm


%post
exit 0


%changelog
#date "+%a %b %d %Y"

* Tue Feb 03 2010 Ethan Vaughn
- 1.0.3-7
- Changed liststatcsv from comma to pipe.

* Tue Feb 02 2010 Ethan Vaughn
- 1.0.3-6
- Added cgi/liststatcsv

* Fri Jun 19 2009 Ethan Vaughn
- 1.0.3-5
- Modified listhost to use top-level hostgroups.
- Removed the "type" and "env" criteria from listhost. 

* Wed Apr 02 2008 Ethan Vaughn
- 1.0.2-1
- Optimized listunack and fixed logic problems with ownership assignment.

* Tue Jan 09 2007 Ethan Vaughn
- 1.0.1-1
- Changed the Ack logic to use 'current_notification_number' and 
  'problem_has_been_acknowledged'.

* Mon Nov 27 2006 Ethan Vaughn
- 1.0.0-30
- Added the category "NAGADMIN" for display in nq-ack.pl.

* Thu Nov 16 2006 Ethan Vaughn
- 1.0.0-29
- Filter out the service notifications when the host itself is down.
 
* Fri Nov 10 2006 Ethan Vaughn
- 1.0.0-28
- Added owner to the output for listunack.

* Wed Nov 08 2006 Ethan Vaughn
- 1.0.0-27
- Remove scheduled_downtime services from list of unacknowledged problems.

* Fri Nov 03 2006 Ethan Vaughn
- 1.0.0-26
- Added list of unacknowledged problems.

* Mon Oct 09 2006 Ethan Vaughn
- 1.0.0-22
- Do not include services that have notifications disabled in the status.

* Thu Sep 11 2006 Ethan Vaughn
- 1.0.0-20
- Added acknowledge and maintenance flags to the 'info' criteria.

* Thu Sep 07 2006 Ethan Vaughn
- 1.0.0-17
- Added listhoststat function.
- Added 'ip' and 'info' criteria to listhosts.
- Moved install directory from /opt to /u01/app.

* Wed Aug 02 2006 Ethan Vaughn
- 1.0.0-5
- Change from text/ascii to text/plain

* Thu Jul 27 2006 Ethan Vaughn
- 1.0.0-4
- Refactor of listHosts
- Added listtypes and listenv

* Tue Jul 25 2006 Ethan Vaughn
- 1.0.0-1

