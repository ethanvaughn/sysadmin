Summary: nquery-client installer/updater
Name: nquery-client
Version: 1.0.1
Release: 4
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
This package includes the command-line programs that connect to the nquery server
via HTTP.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/usr/bin

install -m 755 nq-listcusts.pl $RPM_BUILD_ROOT/usr/bin/nq-listcusts.pl
install -m 755 nq-listenv.pl   $RPM_BUILD_ROOT/usr/bin/nq-listenv.pl  
install -m 755 nq-listhosts.pl $RPM_BUILD_ROOT/usr/bin/nq-listhosts.pl
install -m 755 nq-listtypes.pl $RPM_BUILD_ROOT/usr/bin/nq-listtypes.pl
install -m 755 nq-listunack.pl $RPM_BUILD_ROOT/usr/bin/nq-listunack.pl
install -m 755 nq-ack.pl $RPM_BUILD_ROOT/usr/bin/nq-ack.pl


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

/usr/bin/nq-listcusts.pl
/usr/bin/nq-listenv.pl  
/usr/bin/nq-listhosts.pl
/usr/bin/nq-listtypes.pl
/usr/bin/nq-listunack.pl
/usr/bin/nq-ack.pl


%post
exit 0


%changelog
#date "+%a %b %d %Y"

* Thu Nov 30 2006 Ethan Vaughn
- 1.0.1-4
- Moved binaries to /usr/bin rather than /usr/local/bin.
 
* Fri Nov 17 2006 Ethan Vaughn
- 1.0.1-3
- fixed listcust problem to allow full list with the -i to show ip addresses.

* Fri Nov 10 2006 Ethan Vaughn
- 1.0.1-2
- Added owner to the output.

* Tue Nov 07 2006 Ethan Vaughn
- 1.0.1-1
- Added nq-ack and nq-listunack

* Thu Sep 07 2006 Ethan Vaughn
- 1.0.0-3 
- Added the -n option for info.

* Mon Aug 14 2006 Ethan Vaughn
- 1.0.0-2 
- Refactored to use multiple nagios servers as input.

* Thu Aug 10 2006 Ethan Vaughn
- 1.0.0-1
- Code complete.
