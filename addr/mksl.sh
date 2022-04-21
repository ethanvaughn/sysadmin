#!/bin/bash

# Manage the required symlinks to the common project.
# This script is to be run from the $proj directory during RPM install.


# Relative to $proj directory
PROJ="addr"
C1="../../common"
C2="../../../common"

LIST1="dao/item.pm
dao/saconnect.pm
dao/subnet.pm
lib/conf.pm
lib/item.pm
lib/time.pm
lib/vo.pm
lib/ip.pm
lib/ipfunc.pm
lib/sn.pm
lib/property.pm
dao/ipaddr.pm
dao/property.pm
schema/dbtest.sql
schema/droptables.sh
schema/loadschema.sh
schema/testdata.pl
schema/ipaddr.sql
schema/property.sql
schema/iptype.sql
schema/iptypelink.sql
schema/subnet.sql"

LIST2="www/cgi/helpers.pm
www/tmpl/error_dlg.tmpl
www/tmpl/footer.tmpl
www/tmpl/header.tmpl
www/tmpl/ok_dlg.tmpl"


for i in $LIST1; do
	ln -sf $C1/$i $i
done
for i in $LIST2; do 
	ln -sf $C2/$i $i
done

# misc
ln -sf ../../../common/www/.roll.htaccess www/cgi/.htaccess

exit 0
