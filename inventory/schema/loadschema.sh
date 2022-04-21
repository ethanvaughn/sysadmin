#!/bin/bash

# Change this global to your correct  psql client path:
export PATH=$PATH:/sw/bin

# Import the list of tables in correct sequence for creation:
. ./tables.list

# First drop the tables in correct order.
./droptables.sh

# Add the tables in correct order.
for table in $TABLES; do
	echo "CREATE TABLE: $table"
	psql -U postgres ops  -f $table.sql
done

# Add the app user and assign correct privileges.
#psql -U postgres ops -c "DROP USER appuser;"
#psql -U postgres ops -c "CREATE USER appuser WITH PASSWORD 'ert5oiu7';"
for table in $TABLES; do
	psql -U postgres ops -c "GRANT SELECT,INSERT,UPDATE,DELETE ON $table TO appuser;"
done
for seq in $SEQ; do 
	psql -U postgres ops -c "GRANT ALL ON $seq TO appuser;"
done

# Load the test data if user provides the "-t" command line:
if [ "X${1}" = "X-t" ]; then
	echo
	echo "Loading test data ..."
	./testdata.pl
fi
