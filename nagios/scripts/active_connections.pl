#!/usr/bin/perl

use strict;
use Net::SMTP;
use Getopt::Long;
use Sys::Hostname;

my ($proc,$dest,$service);
GetOptions('C=s' => \$proc, 'H=s' => \$dest, 'S=s' => \$service);

# Try and get the hostname
my $hostname = hostname;
$hostname =~ s/\..*$//;
$hostname =~ tr/[A-Z]/[a-z]/;

if (!$proc || !$dest || !$service) { 
	print "Usage: $0 -C <process name> -H <host to send results to> -S \"service name\"\n";
	exit 1;
}

my $output = `./check_procs -C $proc`;
chomp ($output);
my @data = split(/\s+/,$output);
my $result = $data[2];

# Now send data

my $smtp = Net::SMTP->new($dest) || die $?;
$smtp->mail("active_connections\@$hostname");
$smtp->to("passivecheck\@localhost");
$smtp->data();
$smtp->datasend("CMD: PROCESS_SERVICE_CHECK_RESULT;$hostname;$service;0;OK: $result Active Connections|$result\n");
$smtp->dataend();
$smtp->quit();
