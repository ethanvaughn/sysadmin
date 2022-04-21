#!/usr/bin/perl

use strict;
my $server = $ARGV[0];
my $param = '-Swap_Usage.log';
my $basedir = '/u01/app/nagios/perfdata/';
my $filename = $basedir.$server.$param;

if (-e $filename) {
	my ($retval,$swap);
	open(FILE,$filename);
	while(<FILE>) {
		$retval = $_;
	}
	close(FILE);
	unlink($filename);
	$retval =~ s/^.*=//;
	$retval =~ s/MB//;
	my @vals = split(/;/,$retval);
	if (scalar(@vals) != 5) {
		exit 1;
	} else {
		$swap = (@vals[4] - @vals[0])*1048576;	
	}
	print 'swap:'.$swap;
} else {
	exit 1;
}
