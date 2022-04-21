#!/usr/bin/perl

#########################################################
#
# Purpose: 	Wrapper around Nagios check_ldap
#		to work with centralized monitoring
# Author:  	Jake Kruse
# Date: 	11/23/2007
# Revision History:
#	(11/23/07) Execs check_ldap instead of running
#	 and parsing the output
#	(11/23/07)Initial Release 
#########################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use Getopt::Std;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd; # This will be built later
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Function-specific variables
my $check_ldap = '/u01/app/nagios/libexec/check_ldap';	# Location of Nagios check_ldap executable
my %config; 						# Config directives go here

# Main Body
getArgs();
readThresholds();
runCommand();

sub runCommand {
	# Rather than run the command and capture the output, we have the command line,
	# and trust check_ldap for being smart enough to deal with timeouts and all that fun stuff
	# So just exec it
	exec($cmd) || die $!;
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
			next if /^#/;
			if (/port:(\d+)$/) {
				$config{port} = $1;
				$arg_count++;
				next;
			}
			if (/base_dn:(.*)/) {
				$config{base_dn} = $1;
				$arg_count++;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 2) {
			print 'UNKNOWN: port and base_dn are required arguments';
			exit 3;
		} else {
			# All OK!
			# Build command before returning
			$cmd = "$check_ldap -H $args{I} -b $config{base_dn} -p $config{port} -t $args{t}";
			return;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,'.config not found';
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
		# All of the arguments have been validated
		$suffix = $args{S};
		
		return;
	} else {
		usage();
	}
}

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
		"\n";
	exit 3;
}
