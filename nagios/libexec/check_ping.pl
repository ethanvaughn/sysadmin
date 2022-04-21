#!/usr/bin/perl

#########################################################################################################
#
# Purpose:	Checks whether a given host is reachable via Net::Ping
#		Generally is used where the Nagios check_icmp plugin is
#		not an option, such as environments where the storage system
#		is not directly reachable by the monitoring server.  In these cases,
#		Nagios needs to execute a script on a remote host to ping the target
#		from the remote host, instead of from the monitoring server itself.
#
# $Id: check_ping.pl,v 1.1 2008/04/04 13:14:15 jkruse Exp $
# $Date: 2008/04/04 13:14:15 $
#
#########################################################################################################

use strict;
use Net::Ping;
use Getopt::Std;

my %args;
my $attempts = 5;
my $return_code = -1;
my $timeout = 1;
my $output;

getopts('I:',\%args);
validateArgs();
pingHost();

print $output;
exit $return_code;

sub validateArgs {
	if (!exists($args{I})) {
		usage();
	}
}

sub usage {
	printf('%s: -I <IP Address>%s',$0,"\n");
	exit -1;
}

sub pingHost {
	my $p = Net::Ping->new('tcp',$timeout);
	my $result = 0;
	for (my $i = 0; $i < $attempts; $i++) {
		if ($p->ping($args{I})) {
			$result = 1;
			last;
		}
	}
	if ($result) {
		$output = 'Host responding to pings';	
		$return_code = 0;
	} else {
		$output = sprintf('Host failed to respont to %d ping attempts',$attempts);
		$return_code = 1;
	}
}
