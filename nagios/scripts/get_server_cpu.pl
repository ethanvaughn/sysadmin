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
	if ($retval) {
		print $retval;
	} else {
		print "0";
	}
} else {
	exit 1;
}

# For diags
sub logger {
	open(FILE,">>/u01/app/nagios/perfdata/log.txt");
	print FILE $server." ".localtime()."\n";
	close(FILE);
}
