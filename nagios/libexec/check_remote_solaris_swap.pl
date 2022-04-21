#!/usr/bin/perl

#######################################################################################################
#
# Purpose: 	Checks swap usage on Solaris (tested on Solaris 9)
#
# $Id: check_remote_solaris_swap.pl,v 1.2 2008/03/25 03:48:42 jkruse Exp $
# $Date: 2008/03/25 03:48:42 $
#
#######################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use ArgParse;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = '/usr/sbin/swap -l'; # Command to run, arguments and all (see below for more details on this)
my $optstr = 'I:H:C:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix = 'Swap_Usage';
my $usage = '-I <IP Address> -H <hostname> -C <customer code> -t <optional timeout>';

# Output variables
my ($output,$return_code);

# Function-Specific variables
my %thresholds;
my ($total,$free);

# Main Body
ArgParse::getArgs($optstr,4,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!
	my %values;
	my $values_matched = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		# There could be more than one swap device.  If the following
		# regex matches, do for all lines.
		if ($line =~ /(\d+)\s+(\d+)$/) {
			# Solaris reports each swap device in terms of total
			# and free blocks
			$total+= $1;
			$free+= $2;
		}
	}
	if (defined($total) && defined($free)) {
		# total and free currently are the number of 512-byte blocks
		# available.  Multiply by 512 to convert to bytes
		$total*= 512;
		$free*= 512;
		# Values are in terms of total/free, we want used
		my $used = $total - $free;
		# Now calculate used as a percentage of total
		my $percent_used = ($used/$total)*100;
		# Now compare against thresholds
		if ($percent_used >= $thresholds{critical}) {
			$return_code = 2;
		} elsif ($percent_used >= $thresholds{warning}) {
			$return_code = 1;
		} else {
			$return_code = 0;
		}
		# Now append the actual amount of swap and perf data
		$output.= sprintf('%d%% Used (%d MB used,%d MB total)|%0.f',$percent_used,$used/1048576,$total/1048576,$used);
	} else {
		$output = sprintf('Unable to read output of %s',$cmd);
		$return_code = 3;
	}
	# After all is said and done, just spit out the output and use the exit code defined in return_code
	print $output;
	exit $return_code;
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
			if (/^(warning|critical):(\d{1,2})/) {
				$thresholds{$1} = $2;
			}
		}
		close(FILE);
		if (scalar(keys(%thresholds)) != 2 || $thresholds{warning} >= $thresholds{critical}) {
			# No thresholds found to query
			printf('UNKNOWN: No valid warning & critical thresholds to check,verify syntax of %s/%s-%s',$args{C},$args{H},$suffix);
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
