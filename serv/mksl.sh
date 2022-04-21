#!/bin/bash

# Manage the required symlinks to the common project.
# This script is to be run from the $proj directory during RPM install.


# Relative to $proj directory
PROJ="inventory"
C1="../../common"
C2="../../../common"

LIST1="dao/saconnect.pm
lib/conf.pm
lib/time.pm
lib/vo.pm
schema/dbtest.sql
schema/droptables.sh
schema/loadschema.sh
schema/testdata.pl"

LIST2="www/cgi/helpers.pm
www/tmpl/error_dlg.tmpl
www/tmpl/footer.tmpl
www/tmpl/header.tmpl
www/tmpl/ok_dlg.tmpl"



# First, make sure the required directories exist (if the project has no files
# of it's own in a dir, then the RPM will not create the dir).
mkdir -p ./dao ./lib ./schema ./www/{cgi,tmpl}

# Create the syms:
for i in $LIST1; do
	ln -sf $C1/$i $i
done
for i in $LIST2; do 
	ln -sf $C2/$i $i
done
