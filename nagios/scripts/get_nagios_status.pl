#!/usr/bin/perl

use strict;
use Getopt::Long;

# Globals
my $file = '/u01/app/nagios/var/status.dat';
my ($host,$service);
my $type;

getArgs();
checkFile();
typeSwitch();

sub getArgs {
	GetOptions("H=s" => \$host,"s=s" => \$service);
	if ($host) {
		$type++;
	}
	if ($service) {
		$type++;
	}
}

sub checkFile {
	if (-e $file) {
		return;
	} else {
		print "$file does not exist\n";
		exit 1;
	}
}

sub typeSwitch {
	if ($type == 1) {
		readHost();
	} else if ($type == 2) {
		readService();
	} else {
		exit 1;
	}
}

sub readHost {
	open(FILE,$file) || die "Unable to read file: $?";
	my %host;
	while(<FILE>) {
		if (/^host/) {
			
		}
	}
	close(FILE);
}
