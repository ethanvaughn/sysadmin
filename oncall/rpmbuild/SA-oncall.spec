Summary: SA-oncall installer/updater
Name: SA-oncall
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
Tomax SA oncall application.
This package contains the command-line and CGI web applications for managing
and maintaining the hosting (and Tomax internal) hardware oncall data.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/bin
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/dao
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/lib
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/schema
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/www/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/oncall/www/tmpl

install -m 640 SA-oncall.conf     $RPM_BUILD_ROOT/etc/httpd/conf.d/SA-oncall.conf

install -m 755 mksl.sh            $RPM_BUILD_ROOT/u01/app/oncall/mksl.sh

install -m 755 www/cgi/main       $RPM_BUILD_ROOT/u01/app/oncall/www/cgi/main
install -m 644 www/tmpl/main.tmpl $RPM_BUILD_ROOT/u01/app/oncall/www/tmpl/main.tmpl



%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

%config /etc/httpd/conf.d/SA-oncall.conf

/u01/app/oncall/mksl.sh

/u01/app/oncall/www/cgi/main
/u01/app/oncall/www/tmpl/main.tmpl


%post
echo "Setting up symlinks ..."
cd /u01/app/oncall
./mksl.sh
exit 0


%changelog
#date "+%a %b %d %Y"

* Thu Jun 14 2007 Ethan Vaughn
- 1.0.0-1

