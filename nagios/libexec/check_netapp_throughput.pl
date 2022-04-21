#!/usr/bin/perl

############################################################################################
#
# Purpose:	Checks NetApp Throughput (aggregate across all interfaces)
#
# $Id: check_netapp_throughput.pl,v 1.1 2008/04/04 12:16:16 jkruse Exp $
# $Date: 2008/04/04 12:16:16 $
#
############################################################################################

use strict;
use Getopt::Std;

my $snmp_get = 		'/usr/bin/snmpget'; 		# Full path to snmpget

# Global vals
my %args;						# Command-line arguments go here
my $cmd;						# String that will have the full command built
# Constants
my $sleep = 		5;				# Interval to sleep between queries
my $snmp_args = 	'-v 1 -c public';
my $recv_highpart =	'.1.3.6.1.4.1.789.1.2.2.11.0';	# Recv 32bit lowpart
my $recv_lowpart = 	'.1.3.6.1.4.1.789.1.2.2.12.0';	# Recv 32bit highpart
my $sent_highpart = 	'.1.3.6.1.4.1.789.1.2.2.13.0';	# Sent 32bit lowpart
my $sent_lowpart = 	'.1.3.6.1.4.1.789.1.2.2.14.0';	# Sent 32bit highpart
getopts('I:',\%args);					# Only takes one argument, the IP address of the NetApp

validateArgs();
getThroughput();

sub validateArgs {
	if (!exists($args{I})) {
		usage();
	} else {
		# Build the CMD
		# Sure this is ugly, but it avoids a giant nasty string interpolation
		# and is a little easier to maintain.  Just combine all of the strings
		# together and put the stderr > stdout redirection plus the perl pipe
		# on the end to tell open() that it should execute this string
		$cmd = sprintf(
				'%s %s %s %s %s %s %s 2>&1|',
				$snmp_get,
				$snmp_args,
				$args{I},
				$recv_highpart,
				$recv_lowpart,
				$sent_highpart,
				$sent_lowpart
				);
	}
}

sub usage {
	printf('Usage: %s -I <IP Address>%s',$0,"\n");
	exit 3;
}

sub queryNetApp {
	my @values;
	open(CMD,$cmd) || die $!;
	while(<CMD>) {
		chomp;
		if (/Timeout: No Response from/) {
			print 'Connection timed out';
			exit 2;
		}
		if (/Counter32: /) {
			s/^.*Counter32: //;
			$values[$.-1] = $_;
		}
	}
	close(CMD);
	if (scalar(@values) != 4) {
		print 'Invalid return values';
		exit 3;
	} else {
		# @values has the 4 values we need.  Need to convert these to 64-bit values now
		my $recv = convert32to64($values[0],$values[1]);
		my $sent = convert32to64($values[2],$values[3]);
		return ($recv,$sent);
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
	my $recv = int(($r2 - $r1)/$sleep);
	my $sent = int(($s2 - $s1)/$sleep);
	printf ('%0.2f MB/s In %0.2f MB/s Out|in:%.0f out:%.0f',$recv/1048576,$sent/1048576,$r2,$s2);
	exit 0;
	#print "in: $return_recv out: $return_sent\n";
}
	
# convert32to64: Takes the 32-bit lowpart and highpart of a 64-bit number and returns the original 64-bit number
# This function exists because NetApp does not support 64-bit SNMP counters (NetApps only support SNMP V1), but
# provides this way (using 32 to 64 arithmetic) to obtain the 64-bit counter on an interface.  This is necessary
# because a 32-bit counter resets too fast on a gig (or faster) interface, and you get messed up readings.
sub convert32to64 {
	my ($high,$low) = @_;
	if ($low <= 0) {
		$high++;
	}
	return (($high*4294967296) + $low);
}
