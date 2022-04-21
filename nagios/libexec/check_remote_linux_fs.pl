#!/usr/bin/perl

###########################################################################
#
# Purpose:	Checks filesystem disk space free
#
# $Id: check_remote_linux_fs.pl,v 1.7 2009/05/22 16:02:29 evaughn Exp $
# $Date: 2009/05/22 16:02:29 $
#
###########################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;


# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'df -h -P'; # Command to run, arguments and all (see below for more details on this)
my $optstr = 'I:H:C:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix = 'Disk_Usage';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t (optional)<timeout in seconds>',

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
	my %partitions;
	my $match_count = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		next if $line =~ /^Filesystem/;
		my @values = reverse(split(/\s+/,$line));
		if (exists($thresholds{$values[0]})) {
			$values[1] =~ s/\D//;
			my $percent_free = 100-$values[1];
			# The value of each key in the thresholds hash is a hash reference
			# which is why  this {}->{} notation is used
			if ($percent_free <= $thresholds{$values[0]}->{critical}) {
				# Critcal
				if (!$return_code) {
					$return_code = 2;
				} elsif ($return_code == 1) {
					$return_code = 2;
					$output.= ',';
				}
				$output.= sprintf('%s - %d%% free (%s)',$values[0],$percent_free,$values[2]);
			} elsif ($percent_free <= $thresholds{$values[0]}->{warning}) {
				# Warning
				if (!$return_code) {
					$return_code = 1;
				} else {
					$output.= ',';
				}
				$output.= sprintf('%s - %d%% free (%s)',$values[0],$percent_free,$values[2]);
			}
			# Whether the partition in question is OK, warning, or critical, it matched, therefore 
			# we increment match_count, which is used later to tell if we have any partitions that don't
			# match from our thresholds file
			$match_count++;
			$thresholds{$values[0]}->{status} = 1; # Indicate this partition has been matched
		}
	}
	if ($match_count < scalar(keys(%thresholds))) {
		# One or more partitions in the thresholds file couldn't be found
		# Regardless of what the status is of the partitions that matched, 
		# only output what couldn't be found (since the return code is set to 3
		# So iterate the thresholds hash, and look for any partition whose status != 1
		while (my ($partition,$data) = each(%thresholds)) {
			if ($data->{status} != 1) {
				if (defined($output)) {
					$output.= ',';
				}
				$output.= sprintf('%s missing',$partition);
				$return_code = 3;
			}
		}
	} elsif (!$output) {
		# If output hasn't been defined yet, then it means everything is OK
		$output = 'All Partitions OK';
		$return_code = 0;
	}
	# After all is said and done, just spit out the output and use the exit code defined in return_code
	print $output;
	exit $return_code;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	my $result;
	my $threshold_file = "$basedir/$args{C}/$args{H}-$suffix";
	
	if (! -e $threshold_file) {
		# Threshold missing, check the default file.
		$threshold_file = "$basedir/default/Linux_Disk_Usage";
	}
	$result = open( FILE, $threshold_file );
	if ($result) {
		while(<FILE>) {
			next if /^#/;
			chomp;
			if (/^(\/[A-Za-z0-9\/]*)\s+(\d+)\s+(\d+)/ && $2 > $3) {
				# $1: Partition name
				# $2: Warning threshold
				# $3: Critical threshold
				# Make sure warning > critical
				# The data structure being created here is a hash with two keys: warning,critical
				# This hash is stuffed in the thresholds hash, keyed off the name of the partition.
				# Think of it this way:
				# thresholds{partition name}->{hash of warning and critical thresholds}
				my %p;
				$p{warning} = $2;
				$p{critical} = $3;
				$thresholds{$1} = \%p;
			} else {
				print "UNKNOWN: Invalid partition found: [$_] ($threshold_file)";
				exit 3;
			}
		}
		close( FILE );
		if (scalar(keys( %thresholds )) < 1) {
			# This means we didn't get any valid partitions to check
			print "UNKNOWN: No valid partitions to check. Verify syntax of $threshold_file";
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print "UNKNOWN: Missing both default threshold and file $threshold_file: $!";
		exit 3;
	}
}
