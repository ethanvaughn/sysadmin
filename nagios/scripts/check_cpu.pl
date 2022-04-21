#!/usr/bin/perl

######################################################################
#
#	check_cpu.pl: Gets average CPU usage
#	author: Jake Kruse
#	last revised: 1/7/06
#
######################################################################

use strict;

# OK = 0, WARNING = 1, CRITICAL = 2, UNKNOWN = 3 - Nagios return states
# File Locations -- change as necessary
my $vmstat = '/usr/bin/vmstat'; # Needs to be the full path to vmstat

my $w = 80; # Warning threshold
my $c = 90; # Critical threshold

my $CPUusage; # Return value stored here

findvmstat();
getCPUusage();
returnCPUusage();

sub returnCPUusage {
	my $status;
	my $text;
	if ($CPUusage < $w) {
		$status = 0;
		$text = 'OK';
	} elsif ($CPUusage < $c) {
		$status = 1;
		$text = 'WARNING';
	} else {
		$status = 2;
		$text = 'CRITICAL';
	}
	# For easy integration, the % is removed from the performance data
	print "$text: CPU Usage $CPUusage\%\|$CPUusage\n";
	exit $status;
}

sub getCPUusage {
	# Open vmstat and parse output
	open(CMD,"$vmstat 1 6|") || print "ERROR: unable to open vmstat" && exit 3;
	my @averages; # Each sample's CPU idle time stored here
	my $average; # Where average value gets stored
	my $i = 0; # Used for skipping the first line of output
	while(<CMD>) {
		next if /[a-z]/; # Skips the header column
		$i++; 
		next if $i == 1;
		chomp;
		# Now grab the CPU idle time (last value of vmstat's output)
		my @line = reverse(split());
		my $usage = $line[0];
		if ($usage =~ /^\d{1,3}$/) {
			push(@averages,100-$usage);
		} else {
			# If this happens, it means the value parsed didn't match
			# the regex.  Very very bad
			print "ERROR: Invalid CPU usage data returned\n";
			exit 3;
		}
	}
	close(CMD);
	# Next little bit averages the collected values
	foreach my $val (@averages) {
		$average+= $val;
	}
	$average = int($average/scalar(@averages));
	$CPUusage = $average;
}

sub findvmstat {
	if (-e $vmstat) {
		return;
	} else {
		print "UNKNOWN: vmstat not found\n";
		exit 3;
	}
}
