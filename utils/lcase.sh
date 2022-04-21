#!/bin/bash

# Very quick and dirty filename lowercase tool.

response="n"

echo
echo "Warning: You are about to lowercase all file and directory names in the current directory!"
read -p "Are you sure? [y/N]: " response

if [ "X${response}" = "Xy" -o "X${response}" = "XY" ]; then
	echo
	echo "------------------------------------------------------------------------------"
	for i in *; do 
		newname=$(echo $i | tr A-Z a-z); 
		mv -v $i $newname; 
	done
else
	echo
	echo "Rename operation cancelled."
	echo
	exit 1
fi


