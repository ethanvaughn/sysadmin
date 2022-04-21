#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::objectcache;
use lib::hostgroup;

use strict;

#----- Main ------------------------------------------------------------------
#Globals
my $show = 0;
if ($ARGV[0] eq 'show') {$show = 1};
my $success = 1;
my $failure = 0;


sub t1 {
	my $control = 164;
	my @hostlist = lib::hostgroup::listHosts();

	($show) && print "hostlistsz = $#hostlist     controlsz = $control\n";
	if ($control != $#hostlist) {
		return $failure;
	}
	return $success;
}
print "[1] Test listHosts()    . . .  ";
t1() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



sub t2 {
	my @control = ('jpos2','jpos1','apps2','apps1','rnetdb','rnetlab','mach1');
	my %criteria = (cust => 'pa');
	my @hostlist = lib::hostgroup::listHosts( \%criteria );

	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
	if ($#control != $#hostlist) {
		return $failure;
	}
	# flatten into a string for greppage:
	my $sControl = join( @control );
	foreach (@hostlist) {
		($show) && print "$_\n";
		if ($_ !~ $sControl) {
			return $failure;
		}
	}
	return $success;
}
print "[2] Test listHosts( cust=pa )    . . .  ";
t2() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



#sub t3 {
#	my @control = ('rnetlab');
#	my %criteria = (cust => 'pa', env => 'lab');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	($show) && print "control=[$sControl]\n";
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[3] Test listHosts( cust=pa, env=lab )    . . .  ";
#t3() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



#sub t4 {
#	my @control = ('rnetlab','x16u24');
#	my %criteria = (env => 'lab');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[4] Test listHosts( env=lab )    . . .  ";
#t4() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";




#sub t5 {
#	my @control = ('x16u05','y16u18','y16u21','y16u15','y16u12','x16u30','jpos2','jpos1','apps2','apps1','rnetdb','mach1');
#	my %criteria = (env => 'prod');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[5] Test listHosts( env=prod )    . . .  ";
#t5() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



#sub t6 {
#	my @control = ('mach1','x16u05');
#	my %criteria = (type => 'nas');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[6] Test listHosts( type=nas )    . . .  ";
#t6() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";


#sub t7 {
#	my @control = ('mach1');
#	my %criteria = (cust => 'pa', type => 'nas');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[7] Test listHosts( cust=pa, type=nas )    . . .  ";
#t7() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";



#sub t8 {
#	my @control = ();
#	my %criteria = (cust => 'pa', env => 'lab', type => 'nas');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	return $success;
#}
#print "[8] Test listHosts( cust=pa, env=lab, type=nas )    . . .  ";
#t8() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";




#sub t9 {
#	my @control = ('mach1');
#	my %criteria = (cust => 'pa', env => 'prod', type => 'nas');
#	my @hostlist = lib::hostgroup::listHosts( \%criteria );
#
#	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
#	if ($#control != $#hostlist) {
#		return $failure;
#	}
#	# flatten into a string for greppage:
#	my $sControl = join( @control );
#	foreach (@hostlist) {
#		($show) && print "$_\n";
#		if ($_ !~ $sControl) {
#			return $failure;
#		}
#	}
#	return $success;
#}
#print "[9] Test listHosts( cust=pa, env=prod, type=nas )    . . .  ";
#t9() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";




sub t10 {
	my @control = ('rnetlab 193.1.1.118','jpos2 193.1.1.114','jpos1 193.1.1.101','apps2 193.1.1.42','apps1 193.1.1.41','rnetdb 193.1.1.109','mach1 10.150.10.1');
	my %criteria = (cust => 'pa', ip => '');
	my @hostlist = lib::hostgroup::listHosts( \%criteria );

	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
	if ($#control != $#hostlist) {
		return $failure;
	}

#	print "control: \n";
#	foreach (@control) {
#		print "debug: $_\n";
#	}

	# flatten into a string for greppage:
	my $sControl = join( @control );
	foreach (@hostlist) {
		($show) && print "$_\n";
		if ($_ !~ $sControl) {
			return $failure;
		}
	}
	return $success;
}
print "[10] Test listHosts( cust => 'pa', ip => '' )    . . .  ";
t10() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";




sub t11 {
	my @control = ('rnetlab,193.1.1.118','jpos2,193.1.1.114','jpos1,193.1.1.101','apps2,193.1.1.42','apps1,193.1.1.41','rnetdb,193.1.1.109','mach1,10.150.10.1');
	my %criteria = (cust => 'pa', info => '', ip => '');
	my @hostlist = lib::hostgroup::listHosts( \%criteria );

	($show) && print "hostlistsz = $#hostlist     controlsz = $#control\n";
	if ($#control != $#hostlist) {
		return $failure;
	}

#	print "control: \n";
#	foreach (@control) {
#		print "debug: $_\n";
#	}

	# flatten into a string for greppage:
	my $sControl = join( @control );
	foreach (@hostlist) {
		($show) && print "$_\n";
		if ($_ !~ $sControl) {
			return $failure;
		}
	}
	return $success;
}
print "[11] Test listHosts( cust => 'pa', info => '', ip => '' )    . . .  ";
t11() ? print "[SUCCEEDED]\n" : print "[FAILED]\n";
