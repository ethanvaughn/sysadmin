#!/usr/bin/perl

######################################################################################
#
# Purpose: Checks CPU Usage via mpstat (tested on Solaris 9)
#
# $Id: check_remote_solaris_cpu.pl,v 1.3 2008/03/28 16:03:27 jkruse Exp $
# $Date: 2008/03/28 16:03:27 $
#
######################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use ArgParse;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $sample_count = 10; # Number of samples to collect
my $cmd = sprintf('mpstat 1 %d',$sample_count); # Command to run
my $optstr = 'I:t:';
my $critical_threshold = 80;
my $usage = '-I <IP Address> -t <optional timeout>';

# Notes
# On Solaris the critical threshold is 80 instead of 90 on Linux.  Solaris schedules
# processes such that things have to get real bad before the average CPU usage will exceed
# 90%, but it will often be above 80% when a process has gone runaway.  Chalk one up to
# Sun's brilliance there, they had to go and be different.

# Output variables
my ($output,$return_code);

# Function-specific variables
my %cpus;
my $total_average;

# Main Body
ArgParse::getArgs($optstr,2,\%args,\$usage);
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# This routine will vary considerably from script to script!
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /(\d+).*\s+(\d+)$/) {
			my $usage = 100-$2;
			$cpus{$1}+= $usage;
			$total_average+= $usage;
		}
	}
	# Divide $total_usage by the number of samples
	$total_average/= $sample_count;
	# Now divide by the number of CPUs, which is the number of items in the %cpus hash
	$total_average/= scalar(keys(%cpus));
	if ($total_average >= $critical_threshold) {
		$output = sprintf('%d%|%d',$total_average,$total_average);
		$return_code = 2;
	} else {
		# Overall CPU Usage is OK, but there could be a runaway on one of the CPUs
		# Now check each individual CPU
		while(my ($cpu,$usage) = each(%cpus)) {
			# Usage needs to be divided by the number of samples
			$usage/= $sample_count;
			#print "CPU: $cpu:$usage%\n";
			if ($usage > $critical_threshold) {
				$output.= sprintf('CPU %d %d%,',$cpu,$usage);
			}
		}
		if ($output) {
			# One or more CPUs are critical
			# Chop the trailing comma
			chop($output);
			# Append performance data
			$output.= sprintf('|%d',$total_average);
			# Set the status code
			$return_code = 2;
		} else {
			# Everything is OK
			$output = sprintf('%d%|%d',$total_average,$total_average);
			$return_code = 0;
		}
	}
	print $output;
	exit $return_code;
}
