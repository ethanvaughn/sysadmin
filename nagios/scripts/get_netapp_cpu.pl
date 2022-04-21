#!/usr/bin/perl

use strict;
my $server = $ARGV[0];
my $param = '-CPU_Usage.log';
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
	$retval =~ s/;.*$//;
	print $retval;
} else {
	exit 1;
}
