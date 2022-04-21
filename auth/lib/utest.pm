package lib::utest;
# Functions relating to unit testing.

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;


#----- mkTestFiles -----------------------------------------------------------
# Parameters (datapath)
# Returns nothing.
# Create a hard-coded set of test files for unit testing.
# These files will simulate the assembly algorithm and test the result 
# against a known test case.
sub mkTestFiles { 
	my $dp = shift;

	if (!$dp) {
		return;
	}

	my $lpasswd = "$dp/passwd.test.l";
	my $lshadow = "$dp/shadow.test.l";
	my $lgroup = "$dp/group.test.l";

	my $rpasswd = "$dp/passwd.test.r";
	my $rshadow = "$dp/shadow.test.r";
	my $rgroup = "$dp/group.test.r";

	my $apasswd = "$dp/passwd.test.a";
	my $ashadow = "$dp/shadow.test.a";
	my $agroup = "$dp/group.test.a";



	# Initialize the files:
	`>$lpasswd`;
	`>$lshadow`;
	`>$lgroup`;

	`>$rpasswd`;
	`>$rshadow`;
	`>$rgroup`;

	`>$apasswd`;
	`>$ashadow`;
	`>$agroup`;


	# Simulate the local files
	open( FILE, ">>$lpasswd" ) 
		|| die "Unable to open file [$lpasswd] for writing: $!\n";
	print FILE "root:x:0:0:root:/root:/bin/bash\n";
	close( FILE );

	open( FILE, ">>$lshadow" ) 
		|| die "Unable to open file [$lshadow] for writing: $!\n";
	print FILE 'root:$1$UVCE5v8y$AEhUcmOSnkavw4TwN4NKz/:13318:0:99999:7:::' . "\n";
	close( FILE );

	open( FILE, ">>$lgroup" ) 
		|| die "Unable to open file [$lgroup] for writing: $!\n";
	print FILE "root:x:0:root\n";
	close( FILE );


	# Simulate the remote files
	open( FILE, ">>$rpasswd" ) 
		|| die "Unable to open file [$rpasswd] for writing: $!\n";
	print FILE "fooboy:x:3:40000:Foo Boy:/u01/home/sysadmin:/bin/bash\n";
	print FILE "jrandom:x:1:40000:Jay Random:/u01/home/sysadmin:/bin/bash\n";
	close( FILE );

	open( FILE, ">>$rshadow" ) 
		|| die "Unable to open file [$rshadow] for writing: $!\n";
	print FILE 'fooboy:$1$1EQ6g6r9$yXgzEdXdOzx1p1OS8YGz80:9680:0:3650:7:::' . "\n";
	print FILE 'jrandom:$1$YYMJJfmG$6rQUEydJTR0PkUL3kAjFv/:9678:0:3650:7:::' . "\n";
	close( FILE );

	open( FILE, ">>$rgroup" ) 
		|| die "Unable to open file [$rgroup] for writing: $!\n";
	print FILE "causer:x:150:\n";
	print FILE "netuser:x:40001:evaughn,jeicher,fooboy\n";
	print FILE "sysadmin:x:40000:\n";
	close( FILE );


	# Create the fully combined files
	`cat $lpasswd $rpasswd  > $apasswd`;	
	`cat $lshadow $rshadow > $ashadow`;	
	`cat $lgroup $rgroup > $agroup`;	

}

1
