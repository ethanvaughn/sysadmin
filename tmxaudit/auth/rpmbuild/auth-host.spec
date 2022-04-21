Summary: auth-host installer/updater
Name: auth-host
Version: 1.0.10
Release: 8
License: TomaxInternal
Group: System Environment/Base
Source: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}root
BuildArchitectures: noarch
#BuildRequires: python
#BuildRequires: gettext
#Obsoletes: yum-phoebe
Requires: nquery-client, postgresql, perl, perl-DBI, perl-DBD-Pg
#Prereq: /sbin/chkconfig, /sbin/service

%description
This is the authentication host application for Tomax central netlogin 
user and group management. This application uses PERL and PostgreSQL
to manage a central set of posix users and groups. Client servers query
via SSH and update their own passwd, shadow, and group files.

%prep
%setup

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
%__mkdir_p $RPM_BUILD_ROOT/tmp
%__mkdir_p $RPM_BUILD_ROOT/etc/httpd/conf.d
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/bin
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/dao
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/lib
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/recovery
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/schema
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/tools
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/www/cgi
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/www/css
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/www/html
%__mkdir_p $RPM_BUILD_ROOT/u01/app/auth/www/tmpl

install -m 644 id_rsa.pub $RPM_BUILD_ROOT/tmp/id_rsa.pub
install -m 644 tmxaudit.conf $RPM_BUILD_ROOT/etc/httpd/conf.d/tmxaudit.conf

install -m 755 bin/assigngroup.pl $RPM_BUILD_ROOT/u01/app/auth/bin/assigngroup.pl
install -m 755 bin/dbtest.pl $RPM_BUILD_ROOT/u01/app/auth/bin/dbtest.pl
install -m 755 bin/getshadowline.pl $RPM_BUILD_ROOT/u01/app/auth/bin/getshadowline.pl
install -m 755 bin/groupadd.pl $RPM_BUILD_ROOT/u01/app/auth/bin/groupadd.pl
install -m 755 bin/groupdel.pl $RPM_BUILD_ROOT/u01/app/auth/bin/groupdel.pl
install -m 755 bin/groupmod.pl $RPM_BUILD_ROOT/u01/app/auth/bin/groupmod.pl
install -m 755 bin/mkauthfiles.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkauthfiles.pl
install -m 755 bin/mkclientdata.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkclientdata.pl
install -m 755 bin/mkclientdata4host.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkclientdata4host.pl
install -m 755 bin/mkgroup.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkgroup.pl
install -m 755 bin/mkpasswd.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkpasswd.pl
install -m 755 bin/mkshadow.pl $RPM_BUILD_ROOT/u01/app/auth/bin/mkshadow.pl
install -m 755 bin/passwd.pl $RPM_BUILD_ROOT/u01/app/auth/bin/passwd.pl
install -m 755 bin/resetpwd.pl $RPM_BUILD_ROOT/u01/app/auth/bin/resetpwd.pl
install -m 755 bin/send-reset-email.pl $RPM_BUILD_ROOT/u01/app/auth/bin/send-reset-email.pl
install -m 755 bin/useradd.pl $RPM_BUILD_ROOT/u01/app/auth/bin/useradd.pl
install -m 755 bin/userdel.pl $RPM_BUILD_ROOT/u01/app/auth/bin/userdel.pl
install -m 755 bin/usermod.pl $RPM_BUILD_ROOT/u01/app/auth/bin/usermod.pl

install -m 644 dao/account.pm $RPM_BUILD_ROOT/u01/app/auth/dao/account.pm
install -m 644 dao/group.pm $RPM_BUILD_ROOT/u01/app/auth/dao/group.pm
install -m 644 dao/tmxconnect.pm $RPM_BUILD_ROOT/u01/app/auth/dao/tmxconnect.pm

install -m 644 lib/clientinfo.pm $RPM_BUILD_ROOT/u01/app/auth/lib/clientinfo.pm
install -m 644 lib/conf.pm $RPM_BUILD_ROOT/u01/app/auth/lib/conf.pm
install -m 644 lib/getaccount.pm $RPM_BUILD_ROOT/u01/app/auth/lib/getaccount.pm
install -m 644 lib/getgroup.pm $RPM_BUILD_ROOT/u01/app/auth/lib/getgroup.pm
install -m 644 lib/passwdutils.pm $RPM_BUILD_ROOT/u01/app/auth/lib/passwdutils.pm
install -m 644 lib/updateaccount.pm $RPM_BUILD_ROOT/u01/app/auth/lib/updateaccount.pm
install -m 644 lib/updategroup.pm $RPM_BUILD_ROOT/u01/app/auth/lib/updategroup.pm
install -m 644 lib/utest.pm $RPM_BUILD_ROOT/u01/app/auth/lib/utest.pm

install -m 644 recovery/Rgroup   $RPM_BUILD_ROOT/u01/app/auth/recovery/Rgroup
install -m 644 recovery/Rpasswd  $RPM_BUILD_ROOT/u01/app/auth/recovery/Rpasswd
install -m 644 recovery/Rshadow  $RPM_BUILD_ROOT/u01/app/auth/recovery/Rshadow

install -m 644 schema/accountgrouplink.sql $RPM_BUILD_ROOT/u01/app/auth/schema/accountgrouplink.sql
install -m 644 schema/droptables.sql $RPM_BUILD_ROOT/u01/app/auth/schema/droptables.sql
install -m 755 schema/loadschema.sh $RPM_BUILD_ROOT/u01/app/auth/schema/loadschema.sh
install -m 644 schema/posixaccount.sql $RPM_BUILD_ROOT/u01/app/auth/schema/posixaccount.sql
install -m 644 schema/posixgroup.sql $RPM_BUILD_ROOT/u01/app/auth/schema/posixgroup.sql
install -m 755 schema/testdata.sh $RPM_BUILD_ROOT/u01/app/auth/schema/testdata.sh

install -m 755 tools/authboxen.pl $RPM_BUILD_ROOT/u01/app/auth/tools/authboxen.pl
install -m 755 tools/authboxen.sh $RPM_BUILD_ROOT/u01/app/auth/tools/authboxen.sh

install -m 755 www/cgi/changepass $RPM_BUILD_ROOT/u01/app/auth/www/cgi/changepass
install -m 644 www/html/index.html $RPM_BUILD_ROOT/u01/app/auth/www/html/index.html
install -m 644 www/tmpl/changepass.tmpl $RPM_BUILD_ROOT/u01/app/auth/www/tmpl/changepass.tmpl
install -m 644 www/tmpl/footer.tmpl $RPM_BUILD_ROOT/u01/app/auth/www/tmpl/footer.tmpl
install -m 644 www/tmpl/header.tmpl $RPM_BUILD_ROOT/u01/app/auth/www/tmpl/header.tmpl    
install -m 644 www/tmpl/okdlg.tmpl $RPM_BUILD_ROOT/u01/app/auth/www/tmpl/okdlg.tmpl


%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT


%pre
#exit 0


%files
%defattr(-, root, root)
/tmp/id_rsa.pub
%config /etc/httpd/conf.d/tmxaudit.conf

/u01/app/auth/bin/assigngroup.pl
/u01/app/auth/bin/dbtest.pl
/u01/app/auth/bin/getshadowline.pl
/u01/app/auth/bin/groupadd.pl
/u01/app/auth/bin/groupdel.pl
/u01/app/auth/bin/groupmod.pl
/u01/app/auth/bin/mkauthfiles.pl
/u01/app/auth/bin/mkclientdata.pl
/u01/app/auth/bin/mkclientdata4host.pl
/u01/app/auth/bin/mkgroup.pl
/u01/app/auth/bin/mkpasswd.pl
/u01/app/auth/bin/mkshadow.pl
/u01/app/auth/bin/passwd.pl
/u01/app/auth/bin/resetpwd.pl
/u01/app/auth/bin/send-reset-email.pl
/u01/app/auth/bin/useradd.pl
/u01/app/auth/bin/userdel.pl
/u01/app/auth/bin/usermod.pl

/u01/app/auth/dao/account.pm
/u01/app/auth/dao/group.pm
/u01/app/auth/dao/tmxconnect.pm

%config /u01/app/auth/lib/conf.pm
/u01/app/auth/lib/clientinfo.pm
/u01/app/auth/lib/getaccount.pm
/u01/app/auth/lib/getgroup.pm
/u01/app/auth/lib/passwdutils.pm
/u01/app/auth/lib/updateaccount.pm
/u01/app/auth/lib/updategroup.pm
/u01/app/auth/lib/utest.pm

/u01/app/auth/recovery/Rgroup
/u01/app/auth/recovery/Rpasswd
/u01/app/auth/recovery/Rshadow

/u01/app/auth/schema/accountgrouplink.sql
/u01/app/auth/schema/droptables.sql
/u01/app/auth/schema/loadschema.sh
/u01/app/auth/schema/posixaccount.sql
/u01/app/auth/schema/posixgroup.sql
/u01/app/auth/schema/testdata.sh

/u01/app/auth/tools/authboxen.pl
/u01/app/auth/tools/authboxen.sh

/u01/app/auth/www/cgi/changepass
/u01/app/auth/www/html/index.html
/u01/app/auth/www/tmpl/changepass.tmpl
/u01/app/auth/www/tmpl/footer.tmpl
/u01/app/auth/www/tmpl/header.tmpl
/u01/app/auth/www/tmpl/okdlg.tmpl


%post
# TODO: Make sure postgreSQL is up and running.
# Make sure user tmxaudit exists 
homedir=/u01/home/tmxaudit
grep -q tmxaudit /etc/passwd || useradd -u 301 -d $homedir tmxaudit
grep -q sysadmin /etc/group || groupadd -g 40000 sysadmin
mkdir -p ${homedir}/clientauth
# Install the ssh public key for remote client auth.
[ -f ${homedir}/.ssh ] || mkdir -p ${homedir}/.ssh
chmod 700 ${homedir}/.ssh
cat /tmp/id_rsa.pub >> ${homedir}/.ssh/authorized_keys
chmod 600 ${homedir}/.ssh/authorized_keys
chown -R tmxaudit:sysadmin $homedir
rm -rf /tmp/id_rsa.pub
exit 0


%changelog
#date "+%a %b %d %Y"
* Thu Sep 18 2007 Ethan Vaughn
- 1.0.10-8
- Modify validatePassword to check for min time between changes.

* Thu Mar 29 2007 Ethan Vaughn
- 1.0.10-6
- Display password strength information on the changepass cgi screen.
- Modify validatePassword to check the gecos field to reject first/last name.
- Modify validatePassword to check the previous password and reject if same.

* Wed Mar 28 2007 Ethan Vaughn
- 1.0.9-1
- Enabled policy in shadow for password rotation.

* Wed Mar 14 2007 Ethan Vaughn
- 1.0.8-2
- Removed automatic addition of users to the netuser group.

* Wed Jan 17 2007 Ethan Vaughn
- 1.0.7-2
- Added getshadowline.pl file.


* Tue Dec 15 2006 Ethan Vaughn
- 1.0.7-1
- Removed the gid foreign key constraint in posixgroup table.
- Modified mkclientdata.pl to use hardlinks rather than create 
  mulitple identical tar files.

* Tue Nov 07 2006 Ethan Vaughn
- 1.0.6-3
- Added verbage to the notificaiton email.
- Fixed the usage for the useradd.pl script.

* Thu Oct 26 2006 Ethan Vaughn
- 1.0.6-1
- Added the tools directory and the authboxen scripts to the project.

* Tue Oct 24 2006 Ethan Vaughn
- 1.0.5-12
- Local groups are no longer constrained but sent to the client. The client
  will now defer to the local group saved in the central DB.

* Tue Sep 12 2006 Ethan Vaughn
- 1.0.5-10
- Moved from /opt to /u01/app.
- Added usermod.pl.
- Added vmclient to the client list for testing.

* Fri Aug 11 2006 Ethan Vaughn
- 1.0.5-9
- Added function to create authentication files for hosts based on live data.


* Mon Jul 24 2006 Ethan Vaughn
- 1.0.5-5
- send-reset-email.pl had incorrect path.


* Fri Jul 21 2006 Ethan Vaughn
- 1.0.5-4
- Added CGI application.
- Enabled read/execute permissions for "other". 
- Added httpd/conf.d/tmxaudit.conf
- Fixed transposition of login name and password on changepass form.
- Created stubs for the host lists.

 
* Mon Jul 17 2006 Ethan Vaughn
- 1.0.4-9
- Modified tmxaudit user to uid 301 and primary gid to sysadmin (40000).
- Added sysdba group.
- Added config directive to conf.pm (finally)


* Thu Jul 13 2006 Ethan Vaughn
- 1.0.4-6
- Added ability to regen auth files for a single host.

* Tue Jul 11 2006 Ethan Vaughn
- 1.0.4-5
- Added unit tests.
- Changed names to passwd.r, shadow.r, group.r

* Wed Jun 28 2006 Ethan Vaughn
- 1.0.3-1
- Added ssh key into authorized_keys file for client auth.
- Added client tar creation.

* Wed Jun 28 2006 Ethan Vaughn
- 1.0.0-2
- Added user, group, homedir checks to post.

* Tue Jun 27 2006 Ethan Vaughn
- 1.0.0-1
- Initial
