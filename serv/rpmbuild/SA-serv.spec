Summary: SA-serv installer/updater
Name: SA-serv
Version: 1.0.0
Release: 5
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
#BuildRequires: python
#BuildRequires: gettext
#Obsoletes: yum-phoebe
Requires: perl, perl-DBI, SA-common
#Requires: perl, perl-DBI, perl-DBD-Pg
#Prereq: /sbin/chkconfig, /sbin/service

%description
Tomax SA serv application.
This package contains the command-line and CGI web applications for managing
and maintaining the hosting (and Tomax internal) hardware serv data.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/bin
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/dao
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/lib
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/schema
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/www/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/serv/www/tmpl

install -m 640 SA-serv.conf       $RPM_BUILD_ROOT/etc/httpd/conf.d/SA-serv.conf

install -m 755 mksl.sh            $RPM_BUILD_ROOT/u01/app/serv/mksl.sh

install -m 755 www/cgi/main       $RPM_BUILD_ROOT/u01/app/serv/www/cgi/main
install -m 644 www/tmpl/main.tmpl $RPM_BUILD_ROOT/u01/app/serv/www/tmpl/main.tmpl



%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

%config /etc/httpd/conf.d/SA-serv.conf

/u01/app/serv/mksl.sh

/u01/app/serv/www/cgi/main
/u01/app/serv/www/tmpl/main.tmpl


%post
echo "Setting up symlinks ..."
cd /u01/app/serv
./mksl.sh
exit 0


%changelog
#date "+%a %b %d %Y"

* Thu Jun 14 2007 Ethan Vaughn
- 1.0.0-1

