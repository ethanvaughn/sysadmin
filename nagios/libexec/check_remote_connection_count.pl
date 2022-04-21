#!/usr/bin/perl

#########################################################
#
# Purpose: 	Checks remote connection count
#		This is a purely informational check
#		that only returns critical / unknown
#		from the underlying module, CheckBySSH
# Author:  	Jake Kruse
# Version: 	1.0
# Date: 	09/19/2007
# Revision History:
#		1.0 - Initial Release
#
#########################################################

use lib '/u01/app/nagios/libexec/lib';

# Socket is used because we need some of its functions for handling IP addresses

use strict;
use Socket;
use CheckBySSH;
use Getopt::Std;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'netstat -n --numeric-ports --tcp'; # Command to run, arguments and all (see below for more details on this)
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Output variables
my ($output,$return_code);

# Function-Specific variables
my %excludes;
my %remote_hosts;

# Main Body
getArgs();
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!
	my $count;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	# First do some conversions on the values in the hash to reduce overhead and unnecessary calls to inet_* functions
	my $exclude_netmask = inet_aton($excludes{netmask});
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		my @values = split(/\s+/,$line);
		if ($values[4] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
			# IP address sits in $1 now
			# What this does:
			# If remote host's IP falls *outside* of the exluded subnet/netmask, then we add this host's IP to the remote_hosts hash
			# We use a hash instead of an array since hashes do not allow duplicates.  At the end we can simply count
			# the keys in the hash, and that is the number of unique remote hosts from outside of the excluded subnet/netmask given
			if (!(inet_ntoa(inet_aton($1) & $exclude_netmask) eq $excludes{network})) {
				$remote_hosts{$1} = 1;
			}
		}
	}
	# After all is said and done, just spit out the output and use the exit code defined in return_code
	my $count = scalar(keys(%remote_hosts));
	$output = sprintf('%d|%d',$count,$count);
	$return_code = 0;
	print $output;
	exit $return_code;
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
			if (/^(\w+):(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$/) {
				$excludes{$1} = $2;
			}
		}
		close(FILE);
		if (!(exists($excludes{network}) && exists($excludes{netmask}))) {
			# This means we didn't get any valid partitions to check
			print 'UNKNOWN: Missing network/subnet,verify syntax of '.$args{C}.'/'.$args{H}.'-'.$suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}

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
		' -H <hostname> -C <customer abbrev> -I <ip address> -S "Service Name" -t <timeout in seconds>',
		"\n";
	exit 3;
}
