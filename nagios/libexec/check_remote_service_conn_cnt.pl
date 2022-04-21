#!/usr/bin/perl

##############################################################################
#
#  Gather an aggregate connection count for the specified ports. Note: This
#  is an informational check that only returns CRITICAL / UNKNOWN from the 
#  underlying module, CheckBySSH
#
#  Author: Ethan Vaughn
#
##############################################################################

use lib '/u01/app/nagios/libexec/lib';

# Socket is used because we need some of its functions for handling IP addresses

use strict;
use Socket;
use CheckBySSH;
use Getopt::Std;



# ----- Globals --------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'netstat -an --tcp | grep ESTAB | grep '; # Command to run, the ports and "wc -l" will be appended in readThresholds
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Output variables
my $output;
my $return_code;

# Function-Specific variables
my $ports; # regex pattern of ports to get an aggregate connection count for, see readThresholds.
my %remote_hosts;



#----- Main ------------------------------------------------------------------
getArgs();
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();


#----- parseOutput -----------------------------------------------------------
# Parse the output and exit.
# This routine determines three things: 
#     1. The human readable output for nagios.
#     2. The metric data for Cacti graphing.
#     3. The result_code for WARNING, CRITICAL, etc. 
# Note: Do the processing here rather than in queryHost() since queryHost() is 
# time-sensitive (all of the code in the eval block must be completed 
# before the signal is caught).
sub parseOutput {
	my $count;

	if (exists( $CheckBySSH::query_results{status_code} )) {
		print "$CheckBySSH::query_results{output}";
		exit $CheckBySSH::query_results{status_code};
	}

	# Grab the count from the first line of the output array:
	$count = $CheckBySSH::query_results{output}->[0];
	
	$output = sprintf('%d|%d',$count,$count);
	$return_code = 0;
	print $output;
	exit $return_code;
}



#----- readThresholds --------------------------------------------------------
# Read the thresholds in from the file.
# Returns error (3): 
#     o  if file not found
#     o  After reading the entire file, no valid entries can be found
# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
sub readThresholds {
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^\w+:(.*)$/) {
				$ports = $1;
			}
		}
		close(FILE);
		
		if (!$ports) {
			print 'UNKNOWN: Missing threshold data. Verify syntax of threshold file: ' .
				"$args{C}/$args{H}-$suffix";
			exit 3;
		}
		
		# Finish the command:
		$cmd .= "\'$ports\' | wc -l";
	} else {
		# Threshold file not found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}


#----- getArgs ---------------------------------------------------------------
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
		return;
	} else {
		usage();
	}
}



#----- usage -----------------------------------------------------------------
sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -C <customer abbrev> -I <ip address> -S "Service Name" -t <timeout in seconds>',
		"\n";
	exit 3;
}
