#!/usr/bin/perl

use strict;
use Net::SNMP;
use Getopt::Std;

#my $oid = 'SNMPv2-MIB::sysUpTime.0'; # Doesn't work with Net::SNMP
my $oid = '1.3.6.1.2.1.1.3.0'; # Net::SNMP likes numeric OIDs -- this is equivalent to the first line
our ($opt_I,$opt_C);
my $host;

validateArgs();
query_device();

sub validateArgs {
	getopts('I:C:');  
	if (!$opt_I) {
                usage();
        }
}

sub usage {
        print "Usage: $0 -I <IP address> -C <snmp community>\n";
		print "\t-C is optional; if omitted, public is assumed\n";
        exit 3;
}

sub query_device {
	my $community;
	if (!defined($opt_C)) {
		$community = 'public';
	} else {
		$community = $opt_C;
	}
	my $session = Net::SNMP->session(-timeout=>2,-hostname=>$opt_I,-community=>$community,-port=>161);
	if (!defined($session)) {
		print 'Connection Timed Out: ',$session->error();;
		exit 2;
	}
	my $obj = $session->get_request(-varbindlist => [$oid]);
	if (!defined($obj)) {
		print 'Query Error: ',$session->error();
		exit 2;
	}
	if ($obj->{$oid} =~ /(\d+ days)/) {
		print 'OK: Uptime ',$1;
		exit 0;
	} else {
		print 'UNKNOWN: Unreadable response from ',$opt_I;
		exit 3;
	}
}
