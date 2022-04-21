#!/usr/bin/perl

###########################################################################
#
# Purpose: Checks remote sockets
# Author:  Jake Kruse
# Version: 2.0
# Date: 09/11/2007
# Revision History:
#	2.0 - Changed from eval/die + alarm to use IO::Socket::INET
#		this eliminated the dependence on OS signals and relies
#		on the low-level select() function instead, which is
#		more reliable than signals
#	1.0 - Initial Release (09/11/2007)
###########################################################################

use strict;
use Getopt::Std;
use IO::Socket::INET;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my @args = qw(I H C S t); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined by command-line arguments

# Output variables
my ($output,$return_code);

# Function-Specific variables
my @ports;

# Main Body
getArgs();
readThresholds();
checkSockets();
parseOutput();

sub getArgs {
	# This is the basic code here.  It doesn't do any validation
	# other than a parameter was supplied to each of the arguments.
	# Customize as appropriate to add additional validators
	# If, for example, command-line arguments affect the parameters passed to the remote
	# command, append them to $cmd here (assuming they validate, of course)
	my $validated_args = 0;
	my $optstr = join(':',@args);
	$optstr.= ':'; # join misses the very last colon
	getopts($optstr,\%args);
	foreach my $arg (@args) {
		if(exists($args{$arg})) {
			$validated_args++;
		}
	}
	if ($validated_args == scalar(@args)) {
		return;
	} else {
		usage();
	}
}

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -C <customer abbrev> -S "Service Name" -I <ip address> -t <timeout in seconds>',
		"\n";
	exit 3;
}

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
			if (/^(\d+)$/) {
				my %port;
				$port{number} = $1;
				push(@ports,\%port);
			}
		}
		close(FILE);
		if (scalar(@ports) < 1) {
			# This means we didn't get any valid partitions to check
			print 'UNKNOWN: No valid processes found to check,verify syntax of '.$args{C}.'/'.$args{H}.'-'.$suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}

sub checkSockets {
	foreach my $port (@ports) {
		# IO::Socket::INET provides a much friendlier interface to the select() system call,
		# which implements timeouts on file descriptors.  This is much more reliable (and re-entrant)
		# than OS signals, which are not.  So this is the preferred approach versus eval/die + alarm
		my $sock = IO::Socket::INET->new(
			PeerAddr => $args{I},
			PeerPort => $port->{number},
			Proto => 'tcp',
			Timeout => $args{t}
		);
		# The constructor returns a new IO::Socket::INET object on success, and undef on failure
		if ($sock) {
			# Connection good!
			# Set status to 0
			$port->{status} = 0;
			$port->{message} = 'Accepting Connections';
		} else {
			if ($!) {
				# Now check for errors
				if ($! =~ /Bad file descriptor/) {
					# As counter-intuitive as this would appear, this is the error that gets thrown on a timeout
					$port->{status} = 2;
					$port->{message} = 'Connection timed out';
				} elsif ($! =~ /Connection refused/) {
					# Connection refused throws a much more sane error than connection timeout
					$port->{status} = 2;
					$port->{message} = 'Connection Refused';
				} else {
					# If we get this, it's an uncaught exception
					$port->{status} = 3;
					$port->{message} = 'Internal Error:'.$@;
				}
			} else {
				# Somehow we got a null object back, and no error was set.  Alert SA team..
				# (This should never ever happen!)
				$port->{status} = 3;
				$port->{messages} = 'Unknown Error, contact SA Team';
			}
		}
	}
}

sub parseOutput {
	$return_code = 0;
	foreach my $port (@ports) {
		if ($port->{status} != 0) {
			# 2 is critical, 3 is unknown.  If any port is unknown, it should 'outrank'
			# criticals.  Plus, this will also initially set return_code if everything was OK otherwise
			# Granted, the only circumstance where an unknown occurs is an untrapped error in the eval
			# in checkSockets.  But this does apply for criticals, so maybe it's worth doing
			if ($port->{status} > $return_code) {
				$return_code = $port->{status};
			}
		}
		if ($output) {
			$output.= ',';
		}
		$output.= 'Port '.$port->{number}.':'.$port->{message};
	}
	print $output;
	exit $return_code;
}
