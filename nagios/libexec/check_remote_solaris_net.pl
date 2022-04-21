#!/usr/bin/perl

##############################################################################
# 
# Purpose:	Checks network throughput on given interface.  Unlike
#		the linux version of the same, the interface is
#		required, since the interface name follows the driver
#		being used -- i.e, bge0, ce0, etc.
#
# $Id: check_remote_solaris_net.pl,v 1.1 2008/04/09 21:19:29 jkruse Exp $
# $Date: 2008/04/09 21:19:29 $
#
##############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;
use Getopt::Std;


# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd; # This will be built in readThresholds();
my $optstr = 'I:H:C:S:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <optional timeout> -S "Service Description"',

# Output variables
my ($output,$return_code);

# Function-Specific variables
my @samples;
my $ifname;
my $interval = 10; # Interval between the two samples

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!
	my %partitions;
	my $match_count = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /rbytes64 (\d+).*obytes64 (\d+)/) {
			# RX bytes is $1, TX bytes is $2
			my %sample;
			$sample{rx} = $1;
			$sample{tx} = $2;
			push(@samples,\%sample);
		}
	}
	if (scalar(@samples) == 2) {
		my $rx_bps = (($samples[1]->{rx} - $samples[0]->{rx})/$interval)/1048576;
		my $tx_bps = (($samples[1]->{tx} - $samples[0]->{tx})/$interval)/1048576;
		$output = sprintf ('%0.2f MB/s In %0.2f MB/s Out|in:%0.0f out:%0.0f',$rx_bps,$tx_bps,$samples[1]->{rx},$samples[1]->{tx});
		$return_code = 0;
	} else {
		$output = sprintf('Unable to find data for %s interface',$ifname);
		$return_code = 3;
	}
	print $output;
	exit $return_code;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^interface:(.*)$/) {
				$ifname = $1;
				last;
			}
		}
		close(FILE);
		if (!defined($ifname)) {
			# A thresholds file exists, but it is empty or has invalid syntx
			# On this, we error out
			print 'interface is a required directive in ',$args{C},'/',$args{H},'-'.$suffix;
			exit 3;
		}
	} else {
		printf('%s/%s-%s is missing',$args{C},$args{H},$suffix);
		exit 3;
	}
	if (!defined($ifname)) {
		print 'interface is a required argument';
		exit 3;
	}
	# $cmd is defined here so that $interval can be set.  Since interval is a function-specific var, and
	# $cmd is not, it would look rather strange and not follow the syntax of other scripts.  To keep with
	# the form of others, $cmd is defined here instead.
	$cmd = sprintf('"netstat -k %s;sleep %d;netstat -k %s"',$ifname,$interval,$ifname);
}
