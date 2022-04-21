Summary: send_nsca installer/updater
Name: send_nsca
Version: 1.0.4
Release: 3
License: TomaxaxInternal
Group: System Environment/Base
Source0: %{name}-%{version}.tar.gz
Source1: nsca-2.7.2.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildRequires: libmcrypt
Requires: libmcrypt

%description
Tomax build of the Nagios NCSA client with wrappers for convenince in deployment.

%prep
%setup -a 1

%build
cd nsca-2.7.2/
./configure
make send_nsca

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/usr/bin
%__mkdir_p $RPM_BUILD_ROOT/etc
%__mkdir_p $RPM_BUILD_ROOT/u01/app/utils

install -m 2755 nsca-2.7.2/src/send_nsca $RPM_BUILD_ROOT/usr/bin/send_nsca

install -m 440 send_nsca.cfg       $RPM_BUILD_ROOT/etc/send_nsca.cfg

install -m 644 send_nsca_lib       $RPM_BUILD_ROOT/u01/app/utils/send_nsca_lib
install -m 755 send_nsca_unknown   $RPM_BUILD_ROOT/u01/app/utils/send_nsca_unknown
install -m 755 send_nsca_crit      $RPM_BUILD_ROOT/u01/app/utils/send_nsca_crit 
install -m 755 send_nsca_recovery  $RPM_BUILD_ROOT/u01/app/utils/send_nsca_recovery
install -m 755 send_nsca_warn      $RPM_BUILD_ROOT/u01/app/utils/send_nsca_warn




%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT



%files
%defattr(-, root, root)

/usr/bin/send_nsca
%config /etc/send_nsca.cfg
/u01/app/utils/send_nsca_lib
/u01/app/utils/send_nsca_unknown
/u01/app/utils/send_nsca_crit
/u01/app/utils/send_nsca_recovery
/u01/app/utils/send_nsca_warn



%changelog
#date "+%a %b %d %Y"

* Thu Dec 18 2008 Ethan Vaughn
- 1.0.4-3
- Removed hostname from arg list and will get it from the /bin/hostname command.

* Tue Dec 16 2008 Ethan Vaughn
- 1.0.0-2

