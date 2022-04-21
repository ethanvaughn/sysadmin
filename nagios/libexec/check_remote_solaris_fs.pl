#!/usr/bin/perl

###########################################################################
#
# Purpose:	Checks filesystem disk space free on Solaris
#
# $Id: check_remote_solaris_fs.pl,v 1.2 2008/03/25 02:31:46 jkruse Exp $
# $Date: 2008/03/25 02:31:46 $
#
###########################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use ArgParse;


# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'df -v'; # Command to run
my $optstr = 'I:H:C:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix = 'Disk_Usage';
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
	my %partitions;
	my $match_count = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		# Each line returned by df should look like the following:
		# /u01       /dev/dsk/c1t0d0 61968156 44785618 16562857    74%
		# When df is invoked with -v, it reports the space in 512-byte blocks.  Normally this
		# would be a pain, but Solaris has no Linux equivalent of -P (POSIX-compliant, which
		# is easier to parse).  So, -v works, but requires us to convert 512-byte block
		# counts back to bytes and gigabytes.
		next if $line !~ /^\//;
		my @values = split(/\s+/,$line);
		if (exists($thresholds{$values[0]})) {
			# The one big downside here is we're assuming the output of df
			# is valid -- that the last token is %used, and the token before that
			# is blocks free.  It may be necessary at some point to perform
			# validation on the last and second to last elements of the @values
			# array returned by split
			my $percent_used = $values[scalar(@values)-1];
			$percent_used =~ s/\D//g;
			my $percent_free = 100-$percent_used;
			my $gb_free = sprintf('%.2f GB',($values[scalar(@values)-2]*512)/1073741824);
			# The value of each key in the thresholds hash is a hash reference
			# which is why  this {}->{} notation is used
			my $append_output = 0;
			if ($percent_free <= $thresholds{$values[0]}->{critical}) {
				# Critcal
				if (!$return_code) {
					$return_code = 2;
				} elsif ($return_code == 1) {
					$return_code = 2;
					$output.= ',';
				}
				$append_output = 1;
			} elsif ($percent_free <= $thresholds{$values[0]}->{warning}) {
				# Warning
				if (!$return_code) {
					$return_code = 1;
				} else {
					$output.= ',';
				}
				$append_output = 1;
			}
			if ($append_output) {
				$output.= sprintf('%s - %d%% free (%s)',$values[0],$percent_free,$gb_free);
			}
			# Whether the partition in question is OK, warning, or critical, it matched, therefore 
			# we increment match_count, which is used later to tell if we have any partitions that don't
			# match from our thresholds file
			$match_count++;
			$thresholds{$values[0]}->{status} = 1; # Indicate this partition has been matched
		}
	}
	if ($match_count != scalar(keys(%thresholds))) {
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
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
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
				printf('Invalid partition found: %s (%s/%s-%s)',$_,$args{C},$args{H},$suffix);
				exit 3;
			}
		}
		close(FILE);
		if (scalar(keys(%thresholds)) < 1) {
			# This means we didn't get any valid partitions to check
			printf('No valid partitions to check,verify syntax of %s/%s-%s',$args{C},$args{H},$suffix);
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		printf('%s/%s-%s not found',$args{C},$args{H},$suffix);
		exit 3;
	}
}
