#!/usr/bin/perl

######################################################################################
#
# Purpose: Checks one or more sockets in parallel
# Author:  Jake Kruse
#
# $Id: check_remote_sockets.pl,v 1.9 2009/03/26 19:51:22 evaughn Exp $
# $Date: 2009/03/26 19:51:22 $
#
######################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use IO::Socket::INET;
use threads;
use threads::shared;

# Globals and configuration vars
my $optstr = 		'I:H:C:S:t:';
my $usage = 		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $basedir = 		'/u01/home/nagios/monitoring';
my $suffix;		# Determined by command-line arguments
my %args;		# Where command-line arguments get stored

# Output variables
my ($output,$return_code);

# Function-Specific variables
my @ports :shared;
my @threads;

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
checkSockets();
parseOutput();

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^(\w.*):(\d+)$/) {
				my %port :shared;
				$port{desc} = $1;
				$port{number} = $2;
				push(@ports,\%port);
			}
		}
		close(FILE);
		if (scalar(@ports) < 1) {
			printf('No valid ports/descriptions found to check,verify syntax of %s/%s-%s',$args{C},$args{H},$suffix);
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		printf('%s/%s-%s not found',$args{C},$args{H},$suffix);
		exit 3;
	}
}

sub checkSocket {
	my ($port,$timeout) = @_;
	if (ref($port) ne 'HASH' || !defined($timeout)) {
		return;
	}
	# IO::Socket::INET provides a much friendlier interface to the select() system call,
	# which implements timeouts on file descriptors.  This is much more reliable (and re-entrant)
	# than OS signals, which are not.  So this is the preferred approach versus eval/die + alarm
	my $sock = IO::Socket::INET->new(
			PeerAddr => $args{I},
			PeerPort => $port->{number},
			Proto => 'tcp',
			Timeout => $timeout
			);
	# The constructor returns a new IO::Socket::INET object on success, and undef on failure
	# Since each thread is working on its own port hash ref, we do not need to deal with locking
	if ($sock) {
		# Connection good!
		# Close the socket
		$sock->shutdown(2);
		# Set status to 0
		$port->{status} = 0;
		$port->{message} = 'Listening';
	} else {
		if ($!) {
			my $error = $!;
			# Now check for errors
			if ($error =~ /Bad file descriptor/ || $error =~ /timed out/) {
				# bad file descriptor means there was a timeout, which shouldn't happen normally
				$port->{status} = 2;
				$port->{message} = 'Connection timed out';
			} elsif ($error =~ /Connection refused/) {
				# Connection refused throws a much more sane error than connection timeout
				$port->{status} = 2;
				$port->{message} = 'Connection Refused';
			} else {
				# If we get this, it's an uncaught exception
				$port->{status} = 3;
				$port->{message} = 'Unknown Error:',$error;
			}
		} else {
			# Somehow we got a null object back, and no error was set.  Alert SA team..
			# (This should never ever happen!)
			$port->{status} = 3;
			$port->{messages} = 'Null Object Error - contact SA Team';
		}
	}
}

sub checkSockets {
	# Why are we using threads?
	# Depending on the number of ports, it could take awhile to check them all.
	# Instead of checking them in series, check them in parallel instead
	# This means that this script will take, at most, only $args{t} seconds,
	# as opposed to $args{t}*Number of ports seconds.
	for (my $i = 0; $i < scalar(@ports); $i++) {
		my $thr = threads->create(\&checkSocket,$ports[$i],$args{t});
		push(@threads,$thr);
	}
	# Now wait for each thread to finish
	for (my $i = 0; $i < scalar(@threads); $i++) {
		$threads[$i]->join();
	}
}

sub parseOutput {
	$return_code = 0;
	for (my $i = 0; $i < scalar(@ports); $i++) {
		my $port = $ports[$i];
		# 2 is critical, 3 is unknown.  If any port is unknown, it should 'outrank'
		# criticals.  Plus, this will also initially set return_code if everything was OK otherwise
		# Granted, the only circumstance where an unknown occurs is an untrapped error in the eval
		# in checkSockets.  But this does apply for criticals, so maybe it's worth doing
		if ($port->{status} > $return_code) {
			$return_code = $port->{status};
		}
		if ($port->{status} != 0) {
			$output.= sprintf('%s(%d):%s,',$port->{desc},$port->{number},$port->{message});
		}
	}
	if ($output) {
		# Remove the trailing comma
		chop($output);
	} else {
		# If output was never defined, it means all the ports are listening
		$output = 'All Ports Listening';
	}
	print $output;
	exit $return_code;
}
