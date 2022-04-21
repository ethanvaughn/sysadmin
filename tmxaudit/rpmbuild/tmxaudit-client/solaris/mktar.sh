#!/bin/bash

Version=$(head ../tmxaudit-client.spec | grep "Version" | cut -d " " -f2)
Release=$(head ../tmxaudit-client.spec | grep "Release" | cut -d " " -f2)
INSTALLDIR=tmxaudit-client-$Version-$Release-install

rm -rf tmxaudit-client-$Version-$Release.sol9.tar $INSTALLDIR

mkdir -p $INSTALLDIR/etc/cron.d
mkdir -p $INSTALLDIR/auth-client
mkdir -p $INSTALLDIR/adminscripts
mkdir -p $INSTALLDIR/utils

cp install.sh   $INSTALLDIR/
cp uninstall.sh $INSTALLDIR/

sed 's/^my .sudoers.*$/my $sudoers = "\/usr\/local\/etc\/sudoers";/' ../tmxaudit-client/tmp/modsudoers.pl > $INSTALLDIR/solmodsudoers.pl

cp modhosts.sh                               $INSTALLDIR/
cp modconf.sh                                $INSTALLDIR/
cp solsethomedir.sh                          $INSTALLDIR/
cp bash_profile                              $INSTALLDIR/
cp bashrc                                    $INSTALLDIR/
                                             
cp ../tmxaudit-client/tmxauditrc             $INSTALLDIR/
cp ../tmxaudit-client/ssh/id_rsa             $INSTALLDIR/
cp ../tmxaudit-client/ssh/id_rsa.pub         $INSTALLDIR/
cp ../tmxaudit-client/etc/tmxauditrc         $INSTALLDIR/etc/

cp ../tmxaudit-client/etc/cron.d/authclient  $INSTALLDIR/etc/cron.d/
cp ../tmxaudit-client/etc/cron.d/tmxbu-agent $INSTALLDIR/etc/cron.d/
cp ../tmxaudit-client/etc/cron.d/tmxaudit    $INSTALLDIR/etc/cron.d/

cp ../../../auth-client/ac.pm                $INSTALLDIR/auth-client/
cp ../../../auth-client/authclient.pl        $INSTALLDIR/auth-client/
cp ../../../auth-client/backup.sh            $INSTALLDIR/auth-client/
cp ../../../auth-client/conf.pm              $INSTALLDIR/auth-client/
cp ../../../auth-client/notify-oncall.pl     $INSTALLDIR/auth-client/

# Grab the adminscripts:
find ../../../../adminscripts -type f | grep -v CVS | xargs -I FILE cp FILE  $INSTALLDIR/adminscripts/

# Grab the utils:
find ../../../../utils -type f |grep -v CVS|grep -v "cclog\|sendcmd\|vnc" | xargs -I FILE cp FILE  $INSTALLDIR/utils/

chmod +x $INSTALLDIR/*.sh $INSTALLDIR/*.pl

echo $Version-$Release > $INSTALLDIR/tmxaudit.version

tar cpf tmxaudit-client-$Version-$Release.sol9.tar $INSTALLDIR

exit 0
