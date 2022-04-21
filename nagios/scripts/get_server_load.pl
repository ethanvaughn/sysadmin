#!/usr/bin/perl

use strict;
my $server = $ARGV[0];
my $param = '-Load_Average.log';
my $basedir = '/u01/app/nagios/perfdata/';
my $filename = $basedir.$server.$param;

if (-e $filename) {
	my $retval;
	open(FILE,$filename);
	while(<FILE>) {
		$retval = $_;
	}
	close(FILE);
	my @loads = split(/\s+/,$retval);
	my $newstring;
	foreach (@loads) {
		s/=/:/;
		s/;.*$//;
		$newstring.= $_.' ';
	}
	unlink($filename);
	print $newstring;
} else {
	exit 1;
}
