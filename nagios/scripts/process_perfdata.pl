#!/usr/bin/perl

use strict;
use Getopt::Long;

my ($host,$service,$perfdata,$filename);
my $basedir = '/u01/app/nagios/perfdata/';
GetOptions('H=s' => \$host,'S=s' => \$service,'P=s' => \$perfdata);


validateArgs();
writeToFile();
changePermissions();

sub validateArgs {
	if (!$host || !$service || !(defined($perfdata))) {
		exit 1;
	} else {
		$service =~ s/\ /_/g;
	}
}

sub writeToFile {
	$filename = $basedir.$host.'-'.$service.'.log';
	open(OUT,">$filename");
	print OUT $perfdata;
	close(OUT);
}

sub changePermissions {
	my $res = chmod(0666,$filename);
	if ($res == 1) {
		exit 0;
	} else {
		exit 1;
	}
}

