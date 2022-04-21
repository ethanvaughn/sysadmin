#!/usr/bin/perl

use strict;
use Net::SMTP;
use Getopt::Long;

my $ip = `hostname -i`;
my $hostname = `hostname`;
chomp($hostname);
chomp($ip);
my (%hosts,$dest,$service);
GetOptions('H=s' => \$dest,'s=s' => \$service);

if (!$dest || !$service) {
	print "Usage: $0 -H <SMTP server> -s \"<service name>\"\n";
	exit 1;
}

open(CMD,"netstat -n --numeric-ports --tcp|") || die $?;
while (<CMD>) {
	next if /127\.0\.0\.1/;
	next if /:1521/;
	s/:\d+//g;
	my @line = split();
	next if $line[4] eq $ip;
	if (!exists($hosts{$line[4]})) {
		$hosts{$line[4]} = 1;
	}
}
close(CMD);

$hostname =~ s/\..*$//;
$hostname = lc($hostname);
my $result = scalar(keys(%hosts));

my $smtp = Net::SMTP->new($dest) || die $?;
$smtp->mail("active_connections\@$hostname");
$smtp->to('passivecheck@localhost');
$smtp->data();
$smtp->datasend("CMD: PROCESS_SERVICE_CHECK_RESULT;$hostname;$service;0;OK: $result Active Connections|$result\n");
$smtp->dataend();
$smtp->quit();
