#!/usr/bin/perl

############################################################################
#
# Purpose: Checks load average on Solaris
#
# $Id: check_remote_solaris_load.pl,v 1.2 2008/03/25 02:56:53 jkruse Exp $
# $Date: 2008/03/25 02:56:53 $
#
############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use ArgParse;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'w -u'; # Command to run, arguments and all (see below for more details on this)
my $optstr = 'I:H:C:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix = 'Load_Average';
my $usage = '-I <IP Address> -H <hostname> -C <customer code> -t <optional timeout>';

# Output variables
my ($output,$return_code);

# Function-Specific variables
my %thresholds;

# Main Body
ArgParse::getArgs($optstr,4,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# This routine will vary considerably from script to script!
	# Before we get started, we need to check CheckBySSH::%query_results
	# This will short-circuit if there are any errors
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	my @values;
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /(\d+\.\d+),\s+(\d+\.\d+),\s+(\d+\.\d+)/) {
			@values = ($1,$2,$3);
		} else {
			$output = sprintf('Unable to read output of %s',$cmd);
			$return_code = 3;
		}
		# This should just be one line -- in the event of something weird happening, abort after the first pass
		last;
	}
	if (!$output) {
		# output hasn't been defined, so all of the values are OK.  Now compare the values
		# How this works:
		# 1) build the output string (minus the prefix WARNING/CRITICAL
		# 2) test all critical thresholds
		# 3) if 2) fails, test all warning thresholds
		# 4) if 3) fails, set to OK
		# 4) examine return code and prefix with warning/critical
		$output = sprintf('%.2f,%.2f,%.2f|load1:%.2f load5:%.2f load15:%.2f',$values[0],$values[1],$values[2],$values[0],$values[1],$values[2]);
		# Test warning thresholds
		if (testThresholds($thresholds{critical},\@values)) {
			$return_code = 2;
		} elsif (testThresholds($thresholds{warning},\@values)) {
			$return_code = 1;
		} else {
			$return_code = 0;
		}
	}
	# After all is said and done, just spit out the output and use the exit code defined in return_code
	print $output;
	exit $return_code;
}

sub testThresholds {
	# This function is specific to load averages.  It's used to take an array of load average thresholds, and compare them against
	# load average values, both as array refs.  Returns true (1) if it finds any value in @$values whose matching threshold (same index)
	# is > @$thresholds
	my ($thresholds,$values) = @_;
	if (ref($thresholds) ne 'ARRAY' || ref($values) ne 'ARRAY') {
		# This should never happen, and is a short-circuit
		print 'UNKNOWN: Error in testing load average thresholds, contact SA team';
		exit 3;
	}
	my $return_value;
	for (my $i = 0; $i < 3; $i++) {
		if (@$values[$i] >= @$thresholds[$i]) {
			$return_value = 1;
			last;
		}
	}
	return $return_value;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^(warning|critical):(\d+)\s+(\d+)\s+(\d+)$/) {
				my @values;
				$values[0] = $2;
				$values[1] = $3;
				$values[2] = $4;
				$thresholds{$1} = \@values;
			}
		}
		close(FILE);
		if (scalar(keys(%thresholds)) != 2) {
			# Couldn't read thresholds
			print 'UNKNOWN: No valid warning & critical thresholds to check,verify syntax of ',$args{C},'/',$args{H},'-',$suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
