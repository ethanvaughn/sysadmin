#!/bin/bash

for i in $(<dba.list); do 
	./groupassign.pl -u $i -g vncusers; 
done
