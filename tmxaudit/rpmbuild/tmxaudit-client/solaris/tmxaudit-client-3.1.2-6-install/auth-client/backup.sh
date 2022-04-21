#!/bin/bash

# Rotate backup the authentication files.

FILES="/etc/passwd /etc/shadow /etc/group"

for file in $FILES; do
	for i in 8 7 6 5 4 3 2 1; do
		if [ -f $file.$i ]; then
			j=$[ $i + 1 ]
			cp -p $file.$i $file.$j
		fi
	done
	cp -p $file $file.1
done
