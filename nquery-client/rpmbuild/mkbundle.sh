#!/bin/bash


function usage_exit {
	echo "Create the source tarball and copy it and the spec file"
	echo "to the {remote_path} directory on the remote host."
	echo
	echo "Usage: mkbundle.sh ssh_host remote_path"
	echo
	echo "    ssh_host = SSH host string suitable for use with ssh and scp."
	echo "    remote_path = Path to the RPM build root on the remote host."
	echo
	echo "    eg."
	echo "    mkbundle.sh \"evaughn@10.24.74.9\" ./rpmbuild/nquery-client"
	echo
	exit 1
}

if [ $# -lt 2 ]; then
	usage_exit
fi

ssh_host=$1
remote_path=$2

proj=nquery-client
rpmver=$(grep Version ${proj}.spec | sed 's/Version: //')

# Create the versioned source dir:
mkdir -p ./${proj}-${rpmver}
cp -R ../*.pl ./${proj}-${rpmver}/
#find ./${proj}-${rpmver} -type d | grep CVS | xargs rm -rf 
tar czf ${proj}-${rpmver}.tar.gz ${proj}-${rpmver}/
# Prep remote and move the bundle:
echo "Creating remote directory: $remote_path ..."
ssh $ssh_host "mkdir -p $remote_path"
echo "Copying build bundle and spec file to: $remote_path ..."
scp ${proj}*tar* ${proj}.spec ${ssh_host}:${remote_path}
# Clean up:
rm -rf ${proj}-${rpmver}
rm -rf ${proj}*tar*

exit 0;
