#!/usr/bin/perl

###############################################################################
#
# Purpose:	Counts the number of files in a directory and checks against
#		the defined threshold
#
# $Id: check_remote_linux_file_count.pl,v 1.3 2008/02/06 23:44:31 jkruse Exp $
# $Date: 2008/02/06 23:44:31 $
#
###############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use Getopt::Std;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'ls -A1 '; # The rest will be finished in readThresholds()
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Output variables
my ($output,$return_code);

# Function-specific variables
my %config;

# Main Body
getArgs();
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t},$config{username});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	my $count;
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /(\d+)/) {
			$count = $1;
			last;
		}
	}
	if ($count) {
		$output = sprintf('%d File(s) in %s|%d',$count,$config{directory},$count);
		if ($count > $config{count}) {
			$return_code = 2;
		} else {
			$return_code = 0;
		}
	} else {
		$output = sprintf('Unable to read file count in %s',$config{directory});
		$return_code = 3;
	}
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
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/username:(.*)/) {
				$config{username} = $1;
				$arg_count++;
				next;
			}
			if (/directory:(.*)/) {
				$config{directory} = $1;
				$arg_count++;
				next;
			}
			if (/count:(\d+)/) {
				$config{count} = $1;
				$arg_count++;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 3) {
			# Insufficient arguments
			print 'UNKNOWN: username,directory, and count are requred arguments';
			exit 3;
		} else {
			# Finish the command
			# Note that the pipe needs to be escaped, otherwise CheckBySSH will interpret
			# it as the end of the command, and omit the remainder of the command line
			# that gets passed to SSH
			$cmd.= $config{directory}.' \| wc -l';
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
	if ($validated_args != scalar(@args)) {
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
