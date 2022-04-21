#!/bin/bash

proj=send_nsca
ssh_hosts="evaughn@10.24.74.9 evaughn@10.24.74.13 evaughn@10.24.74.24"
remote_path="./rpmbuild/${proj}"
rpmver=$(grep Version ${proj}.spec | sed 's/Version: //')

# Create the versioned source dir:
mkdir -p ./${proj}-${rpmver}
cp ${proj}.cfg ./${proj}-${rpmver}/
cp wrappers/* ./${proj}-${rpmver}/

tar czf ${proj}-${rpmver}.tar.gz ${proj}-${rpmver}/

# Prep remote and move the bundle:
for ssh_host in $ssh_hosts; do
	echo
	echo "[$ssh_host]"
	echo "Creating remote directory: $remote_path ..."
	ssh $ssh_host "mkdir -p $remote_path"
	echo "Copying bundles and spec file to: $remote_path ..."
	scp ../nsca*tar* ${proj}*tar* ${proj}.spec ${ssh_host}:${remote_path}
done

# Clean up:
rm -rf ${proj}-${rpmver}
rm -rf ${proj}*tar*

exit 0;
