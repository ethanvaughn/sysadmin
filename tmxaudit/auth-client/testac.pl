#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";


use conf;
use ac;

use strict;

#----- Globals --------------------------------------------------------------------
my $success = 1;
my $failure = 0;
my $show = 1;
foreach my $arg (@ARGV) {
	if ($arg eq 'show') {
		$show = 1;
	}
}

#TODO: maybe: built a table of subroutines and map them to command line args to 
#allow user to exec just one test at a time if desired.


#----- Test 200 --------------------------------------------------------------------
sub T200 {
	print "[T200] (normHostname)  . . .  ";
	($show) && print "\n";	
	my $result = $success;
	my $control = "testhost";

	my $hostname = ac::normHostname( "TESThost.tomax.com" );
	($show) && print "    hostname:[$hostname]  control:[$control]\n";	

	if ($hostname ne $control) {
		$result = $failure;
	}
	return $result;
}
T200() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";



#----- Test 500 --------------------------------------------------------------------
sub T500 { 
	print "[T500] (getBundle): Test of incorrect server address  . . .  ";
	($show) && print "\n";	
	#my $msg = ac::getBundle( "10.99.99.99", "hostname" );
	my $msg = ac::getBundle( 1, ["hostname", "11.22.33.44"] );
	($show) && print "    msg:[$msg]\n";	

    if ($msg =~ /Cannot connect/) {
		return $success;
	}

	return $failure;
}
T500() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";



#----- Test 501 --------------------------------------------------------------------
sub T501 {
	print "[T501] (getBundle): Test of file not found  . . .  ";
	($show) && print "\n";	
	
	# Attempt to get the missing file:
	my $msg = ac::getBundle( "10.24.74.13", ["FOOB", "11.22.33.44"] );
	($show) && print "    msg:[$msg]\n";	


    if ($msg) {
		return $failure;
	}

	return $success;
}
T501() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 503 --------------------------------------------------------------------
sub T503 {
	print "[T503] (getBundle): Test getting the tar file . . .  ";
	($show) && print "\n";	
	
	# Prepare for the test by ensuring that the file is there: 
	my @result = `ssh $USER\@10.24.74.13 "(cd clientauth; cp -f vmclient.tar vmclient.bu)" 2>&1`;
	my @result = `scp test/vmclient.tar $USER\@10.24.74.13:clientauth 2>&1`;

	# Get the bundle:
	my $msg = ac::getBundle( 1, ["vmclient", "11.22.33.44"] );
	($show) && print "    msg:[$msg]\n";	

	# Clean up the test:
	my @result = `ssh $USER\@10.24.74.13 "(cd clientauth; rm -f vmclient.tar; mv vmclient.bu vmclient.tar)" 2>&1`;

    if ($msg) {
		return $failure;
	}

	return $success;
}
T503() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";


exit 0;

#----- Test 520 --------------------------------------------------------------------
sub T520 {
	print "[T520] (extractBundle): Test normal file extraction . . .  ";
	($show) && print "\n";	
	
	# Extract the bundle:
	my $msg = ac::extractBundle( "test", "vmclient.tar" );
	($show) && print "    msg:[$msg]\n";	
    if ($msg eq "") {
		# Cleanup
		`rm -f test/passwd.r test/shadow.r test/group.r`;
		return $success;
	}

	# Cleanup
	`rm -f test/passwd.r test/shadow.r test/group.r`;
	return $failure;
}
T520() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";



#----- Test 521 --------------------------------------------------------------------
sub T521 {
	print "[T521] (extractBundle): Test zero size tar file . . .  ";
	($show) && print "\n";	
	
	# Extract the bundle:
	my $msg = ac::extractBundle( "test", "zerobyte.tar" );
	($show) && print "    msg:[$msg]\n";	

    if ($msg =~ "zero") {
		return $success;
	}

	return $failure;
}
T521() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 522 --------------------------------------------------------------------
sub T522 {
	print "[T522] (extractBundle): Test corrupt tar file . . .  ";
	($show) && print "\n";	
	
	# Extract the bundle:
	my $msg = ac::extractBundle( "test", "corrupt.tar" );
	($show) && print "    msg:[$msg]\n";	

    if ($msg =~ "not look like") {
		return $success;
	}

	return $failure;
}
T522() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";



#----- testGetLocal ---------------------------------------------------------------
# Helper that wraps the getLocalPasswd for the passwd and shadow tests below:

#----- Globals -----------------
my $passwd_out = "test/passwd.l";
my $shadow_out = "test/shadow.l";

sub testGetLocal {
	return ac::getLocalPasswd( "test/passwd.full", $passwd_out, "test/shadow.full", $shadow_out);
}


#----- Test 540 --------------------------------------------------------------------
sub T540 {
	print "[T540] (getLocalPasswd): Test extraction of local passwd. . .  ";
	($show) && print "\n";	

	my @passwd_ctrl = (
		"root:x:0:0::/root:/bin/bash",
		"at:x:544:544::/tmp:/bin/nologin",
		"sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin",
		"tomax:x:100:100::/u01/home/tomax:/bin/bash",
		"oracle:x:101:101::/u01/home/oracle:/bin/bash",
		"oas:x:102:101::/u01/home/oas:/bin/bash"
	);

	my $msg = testGetLocal();
	($show) && print "    msg:[$msg]\n";

    if ($msg ne "") {
		# Cleanup
		`rm -f $passwd_out`;
		`rm -f $shadow_out`;
		return $failure;
	}

	open( FILE, "<$passwd_out" ) or return $failure;
	my $bFound = 0;
	while (<FILE>) {
		$bFound = 0;
		my $line = $_;
		chomp $line;
		($show) && print "    $passwd_out:[$line]\n";
		foreach my $ctrl (@passwd_ctrl) {
			if ($ctrl eq $line) {
				$bFound = 1;
				next;
			}
		}
	}
	($bFound) || return $failure;

	return $success;
}
T540() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 541 --------------------------------------------------------------------
# Test the condition that checks for a zero-byte local file.
sub T541 {
	print "[T541] (getLocalPasswd): Test empty local passwd file . . .  ";
	($show) && print "\n";	

	my $msg =  ac::getLocalPasswd( "test/empty", $passwd_out, "test/shadow.full", $shadow_out);
	($show) && print "    msg:[$msg]\n";

    if ($msg =~ /zero bytes/) {
		# Cleanup
		`rm -f $passwd_out`;
		`rm -f $shadow_out`;
		return $success;
	}

	return $failure;
}
T541() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 545 --------------------------------------------------------------------
sub T545 {
	print "[T545] (getLocalPasswd): Test extraction of local shadow . . .  ";
	($show) && print "\n";	

	my @shadow_ctrl = (
		'root:!!:13375:0:3650:7:::',
		'at:!!:13375:0:3650:7:::',
		'sshd:!!:13403:0:99999:7:::',
		'tomax:$1$u.8dalko$yRsQJxIlBX0AzyHHHlDla0:13403:0:99999:7:::',
		'oracle:$1$EIBJc5Fp$PkmwPQRFgTd3VAhsmfCcX.:13403:0:99999:7:::',
		'oas:$1$PuYZWjkx$6qVzP0k4rhYNc3vd6PM6t1:13404:0:99999:7:::'
	);

	my $msg = testGetLocal();
	($show) && print "    msg:[$msg]\n";

    if ($msg ne "") {
		# Cleanup
		`rm -f $passwd_out`;
		`rm -f $shadow_out`;
		return $failure;
	}

	open( FILE, "<$shadow_out" ) or return $failure;
	my $bFound = 0;
	while (<FILE>) {
		$bFound = 0;
		my $line = $_;
		chomp $line;
		($show) && print "    $shadow_out:[$line]\n";
		foreach my $ctrl (@shadow_ctrl) {
			if ($ctrl eq $line) {
				$bFound = 1;
				next;
			}
		}
	}
	($bFound) || return $failure;

	return $success;
}
T545() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 546 --------------------------------------------------------------------
# Test the condition that checks for a zero-byte local file.
sub T546 {
	print "[T546] (getLocalPasswd): Test empty local shadow file . . .  ";
	($show) && print "\n";	

	my $msg =  ac::getLocalPasswd( "test/passwd.full", $passwd_out, "test/empty", $shadow_out);
	($show) && print "    msg:[$msg]\n";

    if ($msg =~ /zero bytes/) {
		# Cleanup
		`rm -f $passwd_out`;
		`rm -f $shadow_out`;
		return $success;
	}

	return $failure;
}
T546() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";





#----- Test 550 --------------------------------------------------------------------
sub T550 {
	print "[T550] (getLocalGroup): Test extraction of local group . . .  ";
	($show) && print "\n";	

	# This is what the test file should look like upon success
	my @control = (
		"at:x:544:",
		"tomax:x:100:",
	);
	my $ctrlfile = "test/group.l.ctrl";
	# Create the control file:
	open( CTRLFILE, ">$ctrlfile" ) or return $failure;
	foreach my $line (@control) {
		print CTRLFILE "$line\n";
	}
	close( CTRLFILE );

	# We need to have the remote files for the getLocalGroup greppage
	my $msg = ac::extractBundle( "test", "vmclient.tar" );
	my $groupl = "test/group.l";
	my $msg = ac::getLocalGroup( "test/group.full", $groupl );
	($show) && print "    msg:[$msg]\n";

    if ($msg ne "") {
		# Cleanup
		`rm -f $groupl $ctrlfile test/*.r`;
		return $failure;
	}

	# Files must be the same:
	`diff $groupl $ctrlfile`;
	if ($? != 0) {
		`rm -f $groupl $ctrlfile test/*.r`;
		return $failure;
	}

	`rm -f $groupl $ctrlfile test/*.r`;
	return $success;
}
T550() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 551 --------------------------------------------------------------------
# Test the condition that checks for a zero-byte local file.
sub T551 {
	print "[T551] (getLocalGroup): Test empty local group file . . .  ";
	($show) && print "\n";	

	my $outfile = "test/group.l";
	my $msg = ac::getLocalGroup( "test/empty", $outfile );
	($show) && print "    msg:[$msg]\n";

    if ($msg =~ /zero bytes/) {
		# Cleanup
		`rm -f $outfile`;
		return $success;
	}

	return $failure;
}
T551() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";



#----- cleanupComposit -----------------------------------------------------------
# Clean the temp files created by the tests; 
sub cleanupComposit {
	`rm -f test/passwd test/shadow test/group`;
	`rm -f test/passwd.l test/shadow.l test/group.l`;
	`rm -f test/passwd.r test/shadow.r test/group.r`;
}


#----- createComposit ------------------------------------------------------------
# Create all files necessary for the composit.
sub createComposit {
	# Create the local parts:
	my $msg = ac::getLocalPasswd( "test/passwd.full", "test/passwd.l", "test/shadow.full", "test/shadow.l" );
	if ($msg ne "") {
		return $msg;
	}

	# We need to have the remote files for the getLocalGroup greppage
	my $msg = ac::extractBundle( "test", "vmclient.tar" );
	$msg = ac::getLocalGroup( "test/group.full", "test/group.l" );
	if ($msg ne "") {
		return $msg;
	}

	my $msg = ac::extractBundle( "test", "vmclient.tar" );
    if ($msg ne "") {
		return $msg;
	}

	$msg = ac::mkComposit( "test", "test" );
    if ($msg ne "") {
		return $msg;
	}
}

#----- chkComposit ----------------------------------------------------------------
# Parameters ( $file, @control )
sub chkComposit {
	my $file = shift;
	my $refcontrol = shift;

	my $msg = createComposit();
	if ($msg ne "") {
		($show) && print "   createComposit:  $msg\n";	
		cleanupComposit();
		return $failure;
	}

	($show) && print "    open( $file )\n";	
	open( FILE, "<$file" ) or return $failure;
	my $bFound = 0;
	while (<FILE>) {
		$bFound = 0;
		my $line = $_;
		chomp $line;
		($show) && print "    $file:[$line]\n";
		foreach my $ctrl (@$refcontrol) {
			if ($ctrl eq $line) {
				$bFound = 1;
				next;
			}
		}
	}
	($show) && print "    bfound=[$bFound]\n";
	($bFound) || return $failure;

	cleanupComposit();
	return $success;
}


#----- Test 560 --------------------------------------------------------------------
sub T560 {
	print "[T560] (mkComposit): Test combining the local and remote passwd . . .  ";
	($show) && print "\n";	

	my @control = (
		"root:x:0:0::/root:/bin/bash",
		"at:x:544:544::/tmp:/bin/nologin",
		"sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin",
		"tomax:x:100:100::/u01/home/tomax:/bin/bash",
		"oracle:x:101:101::/u01/home/oracle:/bin/bash",
		"oas:x:102:101::/u01/home/oas:/bin/bash",
		"dhatch:x:40003:40000:Don Hatch:/u01/home/sysadmin:/bin/bash",
		"evaughn:x:40000:40000:Ethan Vaughn:/u01/home/sysadmin:/bin/bash",
		"jeicher:x:40001:40000:Jon Eicher:/u01/home/sysadmin:/bin/bash",
		"tmxaudit:x:40031:0:tmxaudit:/root:/bin/bash"
	);


	return chkComposit( "test/passwd", \@control );
}
T560() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 561 --------------------------------------------------------------------
sub T561 {
	print "[T561] (mkComposit): Test combining the local and remote shadow . . .  ";
	($show) && print "\n";	

	my @control = (
		'root:!!:13375:0:3650:7:::',
		'at:!!:13375:0:3650:7:::',
		'sshd:!!:13403:0:99999:7:::',
		'tomax:$1$u.8dalko$yRsQJxIlBX0AzyHHHlDla0:13403:0:99999:7:::',
		'oracle:$1$EIBJc5Fp$PkmwPQRFgTd3VAhsmfCcX.:13403:0:99999:7:::',
		'oas:$1$PuYZWjkx$6qVzP0k4rhYNc3vd6PM6t1:13404:0:99999:7:::',
		'dhatch:$1$5lGeI0Nl$h0GxuuBPuKI/h5LE.fXry1:13360:0:3650:7:::',
		'evaughn:$1$gtluq30/$wfjqnl2xiD21IlGGLiseZ1:13374:0:3650:7:::',
		'tmxaudit:$1$Qh/uY9v9$0mN72iouZ351nHCqiL/Oa.:13404:0:3650:7:::',
		'jeicher:$1$WKWgh1c/$KDpoLn.LRHHpvPfZO6K9y0:13362:0:3650:7:::'		
	);


	return chkComposit( "test/shadow", \@control );
}
T561() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 562 --------------------------------------------------------------------
sub T562 {
	print "[T562] (mkComposit): Test combining the local and remote group . . .  ";
	($show) && print "\n";	

	my @control = (
		"at:x:544:",
		"sysadmin:x:40000:",
		"sysdba:x:40001:",
		"root:x:0:",
		"tomax:x:100:",
		"dba:x:101:"
	);


	return chkComposit( "test/group", \@control );
}
T562() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 563 --------------------------------------------------------------------
sub T563 {
	print "[T563] (chkEmpty)  Test empty files . . .  ";
	($show) && print "\n";	

	my $msg = ac::chkEmpty( "test/passwd.full", "test/empty" );
	($show) && print "    msg=[$msg]\n";	

	if ($msg =~ /test.empty/) {
		return $success;
	}

	return $failure;
}
T563() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 564 --------------------------------------------------------------------
sub T564 {
	print "[T564] (chkEmpty)  Test non-empty files . . .  ";
	($show) && print "\n";	

	my $msg = ac::chkEmpty( "test/passwd.full", "test/shadow.full" );
	($show) && print "    msg=[$msg]\n";	

	if ($msg eq "") {
		return $success;
	}

	return $failure;
}
T564() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 570 --------------------------------------------------------------------
sub T570 {
	print "[T570] (verifyAccounts)  Test for key accounts in each auth file . . .  ";
	($show) && print "\n";	

	my @accounts = (
		"sshd",
		"tomax",
		"oracle",
		"oas",
		"tmxaudit",
		"root"
	);

	my @groups = (
		"root",
		"tomax",
		"dba",
		"sysdba",
		"sysadmin"
	);

	my @files = (
		"test/passwd.full",
		"test/shadow.full",
		"test/group.full"
	);
	
	my $msg = ac::verifyAccounts( \@files, \@accounts, \@groups );
	($show) && print "    msg=[$msg]\n";

	if ($msg eq "") {
		return $success;
	}

	return $failure;
}
T570() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";




#----- Test 571 --------------------------------------------------------------------
sub T571 {
	print "[T571] (verifyAccounts)  Test that the verification works . . .  ";
	($show) && print "\n";	

	#The "foo" and "bar" accounts do not exist in the test files.
	my @accounts = (
		"foo",
		"bar",
		"sshd",
		"tomax",
		"oracle",
		"oas",
		"tmxaudit",
		"root"
	);

	# The "foo" and "bar" groups do not exist in the test files.
	my @groups = (
		"foo",
		"bar",
		"root",
		"tomax",
		"dba",
		"sysdba",
		"sysadmin"
	);

	my @files = (
		"test/passwd.full",
		"test/shadow.full",
		"test/group.full"
	);
	
	my $msg = ac::verifyAccounts( \@files, \@accounts, \@groups );
	($show) && print "    msg=[$msg]\n";

	if ($msg =~ /foo/ and $msg =~ /bar/) {
		return $success;
	}

	return $failure;
}
T571() ? print "[SUCCEEDED]\n\n" : print "[FAILED]\n\n";
