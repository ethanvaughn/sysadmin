#!/bin/bash

# Load the schema in correct sequence;

# First drop the tables in correct order.
psql -U postgres tmxaudit -f droptables.sql


# Add the tables in correct order.
psql -U postgres tmxaudit -f posixgroup.sql
psql -U postgres tmxaudit -f posixaccount.sql
psql -U postgres tmxaudit -f accountgrouplink.sql


# Add the app user and assign correct privileges.
psql -U postgres tmxaudit -c "DROP USER tmxaudit;"
psql -U postgres tmxaudit -c "CREATE USER tmxaudit WITH PASSWORD 'ert5foo';"
psql -U postgres tmxaudit -c "GRANT SELECT,INSERT,UPDATE,DELETE ON posixgroup,posixaccount,accountgrouplink TO tmxaudit;"
psql -U postgres tmxaudit -c "GRANT ALL ON posixaccount_id_seq,posixgroup_id_seq TO tmxaudit;"


# Load the test data if user provides the "-t" command line:
if [ "X${1}" = "X-t" ]; then
	echo
	echo "Loading test data ..."
	./testdata.sh
fi
