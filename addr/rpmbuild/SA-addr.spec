Summary: SA-addr installer/updater
Name: SA-addr
Version: 1.0.2
Release: 3
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
Tomax SA Addressing application.
This package contains the command-line and CGI web applications for managing
and maintaining the hosting (and Tomax internal) hardware addr data.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/bin
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/dao
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/lib
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/schema
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/www/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/addr/www/tmpl

install -m 640 SA-addr.conf                $RPM_BUILD_ROOT/etc/httpd/conf.d/SA-addr.conf

install -m 755 mksl.sh                     $RPM_BUILD_ROOT/u01/app/addr/mksl.sh

install -m 755 bin/cidr2int.pl             $RPM_BUILD_ROOT/u01/app/addr/bin/cidr2int.pl
install -m 755 bin/cidr2ip.pl              $RPM_BUILD_ROOT/u01/app/addr/bin/cidr2ip.pl
install -m 755 bin/int2cidr.pl             $RPM_BUILD_ROOT/u01/app/addr/bin/int2cidr.pl
install -m 755 bin/int2ip.pl               $RPM_BUILD_ROOT/u01/app/addr/bin/int2ip.pl
install -m 755 bin/ip2int.pl               $RPM_BUILD_ROOT/u01/app/addr/bin/ip2int.pl

install -m 644 dao/ipaddr.pm               $RPM_BUILD_ROOT/u01/app/addr/dao/ipaddr.pm
install -m 644 dao/subnet.pm             $RPM_BUILD_ROOT/u01/app/addr/dao/subnet.pm

install -m 644 lib/ip.pm                   $RPM_BUILD_ROOT/u01/app/addr/lib/ip.pm
install -m 644 lib/ipfunc.pm               $RPM_BUILD_ROOT/u01/app/addr/lib/ipfunc.pm
install -m 644 lib/sn.pm                   $RPM_BUILD_ROOT/u01/app/addr/lib/sn.pm

install -m 644 schema/ipaddr.sql           $RPM_BUILD_ROOT/u01/app/addr/schema/ipaddr.sql
install -m 644 schema/iptype.sql           $RPM_BUILD_ROOT/u01/app/addr/schema/iptype.sql
install -m 644 schema/iptypelink.sql       $RPM_BUILD_ROOT/u01/app/addr/schema/iptypelink.sql
install -m 644 schema/subnet.sql         $RPM_BUILD_ROOT/u01/app/addr/schema/subnet.sql
install -m 644 schema/tables.list          $RPM_BUILD_ROOT/u01/app/addr/schema/tables.list

install -m 755 www/cgi/ipaddr              $RPM_BUILD_ROOT/u01/app/addr/www/cgi/ipaddr               
install -m 755 www/cgi/iptype              $RPM_BUILD_ROOT/u01/app/addr/www/cgi/iptype
install -m 755 www/cgi/main                $RPM_BUILD_ROOT/u01/app/addr/www/cgi/main
install -m 755 www/cgi/subnet            $RPM_BUILD_ROOT/u01/app/addr/www/cgi/subnet
install -m 755 www/cgi/vl.pm               $RPM_BUILD_ROOT/u01/app/addr/www/cgi/vl.pm
install -m 644 www/tmpl/ipaddr.tmpl        $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/ipaddr.tmpl
install -m 644 www/tmpl/ipaddrlist.tmpl    $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/ipaddrlist.tmpl
install -m 644 www/tmpl/iptype.tmpl        $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/iptype.tmpl
install -m 644 www/tmpl/iptypelist.tmpl    $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/iptypelist.tmpl
install -m 644 www/tmpl/main.tmpl          $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/main.tmpl
install -m 644 www/tmpl/subnet.tmpl      $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/subnet.tmpl
install -m 644 www/tmpl/subnetlist.tmpl  $RPM_BUILD_ROOT/u01/app/addr/www/tmpl/subnetlist.tmpl




%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

%config /etc/httpd/conf.d/SA-addr.conf

/u01/app/addr/mksl.sh

/u01/app/addr/bin/cidr2int.pl
/u01/app/addr/bin/cidr2ip.pl
/u01/app/addr/bin/int2cidr.pl
/u01/app/addr/bin/int2ip.pl
/u01/app/addr/bin/ip2int.pl

/u01/app/addr/dao/ipaddr.pm
/u01/app/addr/dao/subnet.pm

/u01/app/addr/lib/ip.pm
/u01/app/addr/lib/ipfunc.pm
/u01/app/addr/lib/sn.pm

/u01/app/addr/schema/ipaddr.sql
/u01/app/addr/schema/iptype.sql
/u01/app/addr/schema/iptypelink.sql
/u01/app/addr/schema/subnet.sql
/u01/app/addr/schema/tables.list

/u01/app/addr/www/cgi/ipaddr            
/u01/app/addr/www/cgi/iptype
/u01/app/addr/www/cgi/main
/u01/app/addr/www/cgi/subnet
/u01/app/addr/www/cgi/vl.pm
/u01/app/addr/www/tmpl/ipaddr.tmpl
/u01/app/addr/www/tmpl/ipaddrlist.tmpl
/u01/app/addr/www/tmpl/iptype.tmpl
/u01/app/addr/www/tmpl/iptypelist.tmpl
/u01/app/addr/www/tmpl/main.tmpl
/u01/app/addr/www/tmpl/subnet.tmpl
/u01/app/addr/www/tmpl/subnetlist.tmpl


%post
echo Setting up symlinks to common:
cd /u01/app/addr
./mksl.sh
exit 0


%changelog
#date "+%a %b %d %Y"

* Thu Jun 14 2007 Ethan Vaughn
- 1.0.0-0

