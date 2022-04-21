#!/bin/bash


function usage_exit {
	echo "Create the source tarball and copy it and the spec file"
	echo "to the $remote_path/tmxaudit/ directory on the remote host."
	echo
	echo "Usage: mkbundle.sh ssh_host remote_path"
	echo
	echo "    ssh_host = SSH host string suitable for use with ssh and scp."
	echo "    remote_path = Path to the RPM build root on the remote host."
	echo
	echo "    eg."
	echo "    mkbundle.sh \"evaughn@10.24.74.9\" ./rpmbuild/tmxaudit-server"
	echo
	exit 1
}

if [ $# -lt 2 ]; then
	usage_exit
fi

ssh_host=$1
remote_path=$2

rpmver=$(grep Version tmxaudit-server.spec | sed 's/Version: //')

# Create the versioned source dir:
mv tmxaudit-server/ tmxaudit-server-${rpmver}
tar czf tmxaudit-server-${rpmver}.tar.gz tmxaudit-server-${rpmver}/
mv tmxaudit-server-${rpmver} tmxaudit-server
echo "Creating remote directory: $remote_path ..."
ssh $ssh_host "mkdir -p $remote_path"
echo "Copying build bundle and spec file to: $remote_path ..."
scp tmxaudit-server*tar* tmxaudit-server.spec ${ssh_host}:${remote_path}
rm -rf tmxaudit-server*tar*

exit 0;
