#!/usr/bin/perl

###############################################################################################
#
# Name:		check_isd_health.pl
# Purpose:	Using ISD's API to monitor switch status, polls switch to determine
#		its overall health.
#
# $Id: check_isd_health.pl,v 1.1 2008/06/20 20:19:07 jkruse Exp $
# $Date: 2008/06/20 20:19:07 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use IO::Socket::INET;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $optstr = 'I:H:C:S:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my $suffix; # Determined on the fly

my ($output,$status_code);

# Function-specific variables
my %config; # Config directives go here

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
testSocket();

sub testSocket {
	my $sock = IO::Socket::INET->new(
			PeerAddr => $args{I},
			PeerPort => $config{port},
			Proto => 'tcp',
			Timeout => $args{t}
			);
	if ($sock) {
		# Connection is good, but now we need to send a string and
		# read back the response.  The most straight-forward method
		# for this is to use an eval/die pair.

		# Note that we use sysread/syswrite.  Traditional
		# print and while <> are buffered operations, and
		# this socket is unbuffered (see IO::Socket::INET manpage)
		# and mixing buffered calls and a non-buffered file
		# descriptor can lead to unpredictable results

		my $response;
		eval {
			local $SIG{ALRM} = sub { die "timeout\n" };
			alarm($args{t});
			syswrite($sock,$config{send_string});
			sysread($sock,$response,1024);
			close($sock);
			alarm(0);
		};
		if ($@) {
			# We got an error either on the read or write
			if ($@ =~ /timeout/) {
				$output = sprintf('Timeout waiting for Switch Response (Port %d)',$config{port});
				$status_code = 2;
			} else {
				# The catch-all: some other error happened during the read/write to the socket
				$output = $@;
				$status_code = 3;
			}
		} else {
			# No errors, but what's in the output string?
			if ($response =~ /$config{response_string}/) {
				$output = sprintf('Switch Reports Status OK');
				$status_code = 0;
			} else {
				$output = sprintf('Switch Error: Restart Recommended');
				$status_code = 2;
			}
		}
	} else {
		if ($!) {
			my $error = $!;
			# Now check for errors
			if ($error =~ /Bad file descriptor/ || $error =~ /timed out/) {
				# bad file descriptor means there was a timeout, which shouldn't happen normally
				$output = sprintf('Connection timed out (Port %d)',$config{port});
				$status_code = 2;
			} elsif ($error =~ /Connection refused/) {
				# Connection refused throws a much more sane error than connection timeout
				$output = sprintf('Connection Refused (Port %d)',$config{port});
				$status_code = 2;
			} else {
				# If we get this, it's an uncaught exception
				$output = 'Unknown Error:',$error;
				$status_code = 3;
			}
		} else {
			# This means we not only got a null object back from IO::Socket::INET,
			# but no error came back either.  Should never happen.
			$output = 'Null Object Error - Contact SA Team';
			$status_code = 3;
		}
	}
	print $output;
	exit $status_code;
}

sub readThresholds {
	# This function is for reading the config in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/; # cheap and easy way to allow for comments
			if (/^port:(\d+)$/) {
				$config{port} = $1;
				$arg_count++;
				next;
			} elsif (/^send_string:(.*)/) {
				$config{send_string} = $1;
				$arg_count++;
				next;
			} elsif (/^response_string:(.*)/) {
				$config{response_string} = $1;
				$arg_count++;
				next;
			} elsif (/(.*):(.*)/) {
				# Get all optional directives
				$config{$1} = $2;
			}
		}
		close(FILE);
		if ($arg_count != 3) {
			print 'port, send_string and response_string are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
