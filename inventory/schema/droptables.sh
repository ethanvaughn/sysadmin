#!/bin/bash

# Change this to your psql client path:
export PATH=$PATH:/sw/bin

# Import the list of tables:
. ./tables.list

for table in $DROPTABLES; do
	echo "DROP TABLE $table"
	psql -U postgres ops -c "DROP TABLE $table;"
done
