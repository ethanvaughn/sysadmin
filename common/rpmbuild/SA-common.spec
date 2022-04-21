Summary: SA-common installer/updater
Name: SA-common 
Version: 1.0.2
Release: 5
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
Requires: perl, perl-DBI

%description
Library functions common to SA projects.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/bin
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/dao
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/lib
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/schema
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/www/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/www/html/css
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/www/html/images
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/www/html/js
%__mkdir_p $RPM_BUILD_ROOT/u01/app/common/www/tmpl

install -m 644 SA-common.conf       $RPM_BUILD_ROOT/etc/httpd/conf.d

install -m 644 bin/mkhtpasswd.sh       $RPM_BUILD_ROOT/u01/app/common/bin/mkhtpasswd.sh

install -m 644 dao/device.pm           $RPM_BUILD_ROOT/u01/app/common/dao/device.pm
install -m 644 dao/saconnect.pm        $RPM_BUILD_ROOT/u01/app/common/dao/saconnect.pm

install -m 644 lib/conf.pm             $RPM_BUILD_ROOT/u01/app/common/lib/conf.pm
install -m 644 lib/device.pm           $RPM_BUILD_ROOT/u01/app/common/lib/device.pm
install -m 644 lib/time.pm             $RPM_BUILD_ROOT/u01/app/common/lib/time.pm
install -m 644 lib/vo.pm               $RPM_BUILD_ROOT/u01/app/common/lib/vo.pm

install -m 644 schema/dbtest.sql       $RPM_BUILD_ROOT/u01/app/common/schema/dbtest.sql
install -m 644 schema/device.sql       $RPM_BUILD_ROOT/u01/app/common/schema/device.sql
install -m 755 schema/droptables.sh    $RPM_BUILD_ROOT/u01/app/common/schema/droptables.sh
install -m 755 schema/loadschema.sh    $RPM_BUILD_ROOT/u01/app/common/schema/loadschema.sh
install -m 644 schema/posixaccount.sql $RPM_BUILD_ROOT/u01/app/common/schema/posixaccount.sql
install -m 644 schema/tables.list      $RPM_BUILD_ROOT/u01/app/common/schema/tables.list
install -m 644 schema/testdata.pl      $RPM_BUILD_ROOT/u01/app/common/schema/testdata.pl

install -m 755 www/cgi/401             $RPM_BUILD_ROOT/u01/app/common/www/cgi/401
install -m 644 www/cgi/helpers.pm      $RPM_BUILD_ROOT/u01/app/common/www/cgi/helpers.pm
install -m 644 www/html/css/ops.css    $RPM_BUILD_ROOT/u01/app/common/www/html/css/ops.css
install -m 644 www/html/css/tabmenu.css             $RPM_BUILD_ROOT/u01/app/common/www/html/css/tabmenu.css
install -m 644 www/html/images/opslogo-bank.png     $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-bank.png
install -m 644 www/html/images/opslogo-chinese.png  $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-chinese.png
install -m 644 www/html/images/opslogo-chinese2.png $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-chinese2.png
install -m 644 www/html/images/opslogo-herc.png     $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-herc.png
install -m 644 www/html/images/opslogo-japanese.png $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-japanese.png
install -m 644 www/html/images/opslogo-korean.png   $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-korean.png
install -m 644 www/html/images/opslogo-stencil.png  $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-stencil.png
install -m 644 www/html/images/opslogo-type.png     $RPM_BUILD_ROOT/u01/app/common/www/html/images/opslogo-type.png
install -m 644 www/html/images/tabmenu-bg.png       $RPM_BUILD_ROOT/u01/app/common/www/html/images/tabmenu-bg.png
install -m 644 www/html/images/tabmenu-bg2.png      $RPM_BUILD_ROOT/u01/app/common/www/html/images/tabmenu-bg2.png
install -m 644 www/html/images/tabmenu-bg3.png      $RPM_BUILD_ROOT/u01/app/common/www/html/images/tabmenu-bg3.png
install -m 644 www/html/js/ops.js      $RPM_BUILD_ROOT/u01/app/common/www/html/js/ops.js
install -m 644 www/tmpl/401.tmpl       $RPM_BUILD_ROOT/u01/app/common/www/tmpl/401.tmpl
install -m 644 www/tmpl/error_dlg.tmpl $RPM_BUILD_ROOT/u01/app/common/www/tmpl/error_dlg.tmpl
install -m 644 www/tmpl/footer.tmpl    $RPM_BUILD_ROOT/u01/app/common/www/tmpl/footer.tmpl   
install -m 644 www/tmpl/header.tmpl    $RPM_BUILD_ROOT/u01/app/common/www/tmpl/header.tmpl   
install -m 644 www/tmpl/ok_dlg.tmpl    $RPM_BUILD_ROOT/u01/app/common/www/tmpl/ok_dlg.tmpl   







%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)

%config /etc/httpd/conf.d/SA-common.conf

/u01/app/common/bin/mkhtpasswd.sh

/u01/app/common/dao/device.pm
/u01/app/common/dao/saconnect.pm

%config /u01/app/common/lib/conf.pm
/u01/app/common/lib/device.pm
/u01/app/common/lib/time.pm
/u01/app/common/lib/vo.pm

/u01/app/common/schema/dbtest.sql
/u01/app/common/schema/device.sql
/u01/app/common/schema/droptables.sh
/u01/app/common/schema/loadschema.sh
/u01/app/common/schema/posixaccount.sql
/u01/app/common/schema/tables.list
/u01/app/common/schema/testdata.pl

/u01/app/common/www/cgi/401
/u01/app/common/www/cgi/helpers.pm
/u01/app/common/www/html/css/ops.css
/u01/app/common/www/html/css/tabmenu.css
/u01/app/common/www/html/images/opslogo-bank.png
/u01/app/common/www/html/images/opslogo-chinese.png
/u01/app/common/www/html/images/opslogo-chinese2.png
/u01/app/common/www/html/images/opslogo-herc.png
/u01/app/common/www/html/images/opslogo-japanese.png
/u01/app/common/www/html/images/opslogo-korean.png
/u01/app/common/www/html/images/opslogo-stencil.png
/u01/app/common/www/html/images/opslogo-type.png
/u01/app/common/www/html/images/tabmenu-bg.png
/u01/app/common/www/html/images/tabmenu-bg2.png
/u01/app/common/www/html/images/tabmenu-bg3.png
/u01/app/common/www/html/js/ops.js
/u01/app/common/www/tmpl/401.tmpl
/u01/app/common/www/tmpl/error_dlg.tmpl
/u01/app/common/www/tmpl/footer.tmpl
/u01/app/common/www/tmpl/header.tmpl
/u01/app/common/www/tmpl/ok_dlg.tmpl


%post
echo "Create symlink for the htpasswd cron"
ln -sf /u01/app/common/bin/mkhtpasswd.sh /etc/cron.daily/mkhtpasswd.sh
exit 0


%changelog
#date "+%a %b %d %Y"

* Thu Nov 08 2007 Ethan Vaughn
- 1.0.2-5
- htpassword created daily from the /etc/passwd + /etc/shadow for web auth.
- 401 error handling.

* Thu Sep 06 2007 Ethan Vaughn
- 1.0.1-5
- Added lib/vo.pm, ops.css

* Thu Jul 26 2007 Ethan Vaughn
- 1.0.1-3
- Added schema/ items. 

* Wed Jul 25 2007 Ethan Vaughn
- 1.0.1-1
- Added lib/time.pm and the initial tmpl files.


* Thu Jun 14 2007 Ethan Vaughn
- 1.0.0-0
- Initial test deployment.

