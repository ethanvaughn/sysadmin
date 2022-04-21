#!/usr/bin/perl

use strict;
use Getopt::Long;
my ($customer,$status,$state,$hostname,$hostdesc,$servicedesc,$serviceoutput,$message,$severity);
GetOptions('status=s' => \$status, 'state=s' => \$state, 'H=s' => \$hostname, 'Hdesc=s' => \$hostdesc, 'S=s' => \$servicedesc, 'Soutput=s' => \$serviceoutput, 'C=s' => \$customer);

if (!($customer && $status && $state && $hostname && $hostdesc && $servicedesc && $serviceoutput)) {
	print "Usage: $0 -C <CA customer> -H <hostname> -Hdesc <host description> -S <service description> -Soutput <service output> -status <OK|WARNING|CRITICAL> -state <HARD|SOFT>\n";
	exit 1;
}

# Fix ()s
$serviceoutput =~ s/\(|\)//g;


if ($status eq 'OK') {
	# Update portal
	$severity = 1;
	$message = "$hostname - $hostdesc is $status: $serviceoutput";
} elsif ($status eq 'WARNING') {
	if ($state eq 'HARD') {
		# update portal
		$severity = 2;
		$message = "$hostname - $hostdesc is $status: $serviceoutput";
	}
} elsif ($status eq 'CRITICAL') {
	if ($state eq 'HARD') {
		# update portal
		$severity = 3;
		$message = "$hostname - $hostdesc is $status: $serviceoutput";
	}
} else {
	# unknown state: exit
	exit 0;
}

system("ssh administrator\@10.24.74.19 cmd.exe /C c:/nagiostoportal.pl $customer $severity $message");
