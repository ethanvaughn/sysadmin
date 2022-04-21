#!/usr/bin/perl

####################################################################################################################
#
# Name:		check_netapp_disk_throughput.pl
# Purpose:	Queries via SNMP disk throughput counters
#
# $Id: check_netapp_disk_throughput.pl,v 1.2 2008/01/21 17:57:54 jkruse Exp $
# $Date: 2008/01/21 17:57:54 $
#
####################################################################################################################

use strict;
use Getopt::Std;

# Global vals
my ($cmd,%args);
# Constants
my $sleep = 3;
my $snmp_cmd = '/usr/bin/snmpget -v 1 -c public ';
# OIDs
my $read_highpart = '.1.3.6.1.4.1.789.1.2.2.15.0';
my $read_lowpart = '.1.3.6.1.4.1.789.1.2.2.16.0';
my $write_highpart = '.1.3.6.1.4.1.789.1.2.2.17.0';
my $write_lowpart = '.1.3.6.1.4.1.789.1.2.2.18.0';

getopts('I:',\%args);		# Get command line arguments
validateArgs();			# Parse them
getThroughput();		# Do the funk

sub validateArgs {
	if (!exists($args{I})) {
		usage();
	} else {
		# Build the CMD
		$cmd = $snmp_cmd." $args{I} $read_highpart $read_lowpart $write_highpart $write_lowpart";
	}
}

sub usage {
	print 'Usage: ',$0,' -I <IP address>',"\n";
	exit 3;
}

sub queryNetApp {
	my @values;
	open(CMD,"$cmd 2>&1|") || die $!;
	while(<CMD>) {
		chomp;
		if (/Timeout: No Response from/) {
			print 'CRITICAL: Connection timed out';
			exit 2;
		}
		if (/Counter32: (\d+)$/) {
			# $. is the line number, starting from 1.  Take all 4 of these SNMP responses
			# and stick them in indicides 0,1,2,4 of @values
			# Later, these will be converted back to real numbers
			$values[$.-1] = $1;
		}
	}
	close(CMD);
	if (scalar(@values) != 4) {
		# Short-circuit: if we didn't get 4 values back, something is really wrong.  Abort
		print 'Invalid return values';
		exit 3;
	} else {
		# @values has the 4 values we need.  Need to convert these to 64-bit values now
		my $read = convert32to64($values[0],$values[1]);
		my $write = convert32to64($values[2],$values[3]);
		return ($read,$write);
	}
}

sub getThroughput {
	# The thing with querying these OIDs is they are cumulative.  So we need to query twice and subtract
	# the first number from the last.  Also have to convert the high/lowparts to 64-bits
	# Now get the first reading
	my ($r1,$s1) = queryNetApp();
	sleep $sleep;
	my ($r2,$s2) = queryNetApp();
	#print "$r2 $r1|$s2 $s1\n"; # Debugging
	my $read = int(($r2 - $r1)/$sleep);
	my $write = int(($s2 - $s1)/$sleep);
	printf('%0.2f MB/s Read %0.2f MB/s Write|in:%.0f out:%.0f',$read/1048576,$write/1048576,$r2,$s2);
	exit 0;
	#print "in: $return_read out: $return_write\n";
}
	
sub convert32to64 {
	my ($high,$low) = @_;
	if ($low <= 0) {
		$high++;
	}
	return (($high*4294967296) + $low);
}
