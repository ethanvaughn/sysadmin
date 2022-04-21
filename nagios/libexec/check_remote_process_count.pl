#!/usr/bin/perl

#############################################################################################################
#
# Purpose: 	Checks to to see how many procs are running that contain
#		the given string found in the threshold file
#
# $Id: check_remote_process_count.pl,v 1.4 2008/06/12 13:55:21 jkruse Exp $
# $Date: 2008/06/12 13:55:21 $
#
#############################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;

# Globals and configuration vars
my %args;		# Where command-line arguments get stored
my $suffix;		# Determined on the fly
my $cmd = 		'pgrep -f '; # Command to run, process name will be added later
my $basedir =		'/u01/home/nagios/monitoring';
my $optstr =		'I:H:C:S:t:';
my $usage =		'-H <hostname> -C <customer abbrev> -I <ip address> -t <optional timeout> -S "Service Name"',

# Output variables
my ($output,$return_code);

# Function-specific variables
my $process; # The process we're counting

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd.$args{u},$args{I},$args{t}); # Add username to ps -f -u
parseOutput();

sub parseOutput {
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	my $count = 0;
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		$count++;
	}
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
	my $process_found = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^\w+/) {
				# Append what was found here to $cmd
				$cmd.= $_;
				$process_found = 1;
				last;
			}
		}
		close(FILE);
		if (!$process_found) {
			# This means we didn't get any valid partitions to check
			print 'No valid process found to check,verify syntax of '.$args{C}.'/'.$args{H}.'-'.$suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
