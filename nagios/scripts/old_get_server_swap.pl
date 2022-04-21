#!/usr/bin/perl

use strict;
my $server = $ARGV[0];
my $param = '-Swap_Usage.log';
my $basedir = '/u01/app/nagios/perfdata/';
my $filename = $basedir.$server.$param;

if (-e $filename) {
	my $retval;
	open(FILE,$filename);
	while(<FILE>) {
		$retval = $_;
	}
	close(FILE);
	unlink($filename);
	$retval =~ s/^.*=//;
	$retval =~ s/MB.*$//;
	if ($retval =~ /\D/) {
		exit 1;
	} else {
		$retval*= 1048576;
		print 'swap:'.$retval;
	}
} else {
	exit 1;
}
