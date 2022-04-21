#!/usr/bin/perl

use strict;
use Getopt::Long;
use Net::SMTP;
use Sys::Hostname;

# SMTP Server to mail results to
my $dest = '10.24.74.9';

my (%processes,$message,$status,$file,$service);
GetOptions('S=s' => \$service, 'f=s' => \$file);

if (!$service || !$file) {
	print "Usage: $0 -S <service name> -f <process list file>\n";
	print "\tExamples:\n";
	print "\t$0 -S \"Domino Processes\" -f processlist\n";
	exit 0;
}

if (-e $file) {
	open(INPUT,$file) || die "Unable to open file: $!";
	while(<INPUT>) {
		chomp;
		if (/^\w+$/) {
			$processes{$_} = 1;
		}
	}
	close(INPUT);
	if (scalar(keys(%processes)) > 0) {
		open(CMD,"ps -e|") || die "Unable to run ps -ef: $!";
		while(<CMD>) {
			my @line = split();
			if ($line[3] =~ /^\w+$/) {
				if (exists($processes{$line[3]})) {
					$processes{$line[3]}++;
				}
			}
		}
		my @notrunning;
		while(my ($key,$val) = each(%processes)) {
			if ($val == 1) {
				push(@notrunning,$key);
			}
		}
		if (scalar(@notrunning > 0)) {
			$message = "CRITICAL: ";
			foreach my $proc (@notrunning) {
				$message.= $proc.' ';
			}
			$message.= "Not Running";
			$status = 2;
		} else {
			$message = "OK: All Processes Running";
			$status = 0;
		}
	} else {
		$message = "CRITICAL: No processes in processfile $file";
		$status = 2;
	}
} else {
	$message = "CRITICAL: process file ($file) not found";
	my $status = 2;
}

my $hostname = lc(hostname);
$hostname =~ s/\..*$//;

my $smtp = Net::SMTP->new($dest) || die $?;
$smtp->mail("_connections\@$hostname");
$smtp->to('passivecheck@localhost');
$smtp->data();
$smtp->datasend("CMD: PROCESS_SERVICE_CHECK_RESULT;$hostname;$service;$status;$message\n");
$smtp->dataend();
$smtp->quit();
