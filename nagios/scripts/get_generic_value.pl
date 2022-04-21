#!/usr/bin/perl

## Purpose: Retrieve single-values from a .log file.  
## The main difference is that instead of hard-coding $param, we are making it the first argument passed in
## Arguments: $ARGV[0]: the log type (i.e, CPU_Usage.log, Disk_Utilization.log
##            $ARGV[1]: server name (i.e, s19u22, s19u24)

use strict;
my $param = $ARGV[0];
my $server = $ARGV[1];
my $basedir = '/u01/app/nagios/perfdata/';
my $filename = $basedir.$server.$param;

if (!(defined($param) && defined($server))) {
	exit 1;
}

if (-e $filename) {
	my $retval;
	open(FILE,$filename) || exit 1;
	while(<FILE>) {
		$retval = $_;
	}
	close(FILE);
	unlink($filename);
	if ($retval) {
		print $retval;
	} else {
		print "0";
	}
} else {
	exit 1;
}
