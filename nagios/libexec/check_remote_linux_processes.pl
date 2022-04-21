#!/usr/bin/perl

###############################################################
#
# Purpose:	Checks to see if processes given are running
#
# $Id: check_remote_linux_processes.pl,v 1.4 2009/03/26 19:51:22 evaughn Exp $
# $Date: 2009/03/26 19:51:22 $
#
###############################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckLib;
use CheckBySSH;
use Getopt::Std;

#----- Globals ---------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'ps -o comm,args h -u '; # Only partially built, user (-u xxxx) gets added when passed to CheckBySSH::queryHost()
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Output variables
my ($output,$return_code);

# Function-specific variables
my ( %processes, $username );




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
		# All of the arguments have been validated
		$suffix = CheckLib::normalizeServDesc( $args{S} );
		return;
	} else {
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




#----- readThresholds --------------------------------------------------------
sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	my $threshold_file = "$basedir/$args{C}/$args{H}-$suffix";

	my $result = open( FILE, $threshold_file );
	if ($result) {

		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^user:(\w+)$/) {
				$username = $1;
				$cmd .= $username;
			} elsif (/\w+/) {
				$processes{$_} = 1;
			}
		}
		close(FILE);
		
		if (scalar( keys( %processes ) ) < 1) {
			print 'UNKNOWN: No valid processes found to check,verify syntax of ' . $threshold_file;
			exit 3;
		} elsif (!$username) {
			# Somewhere in the file a user needs to be specified that we're searching for processes to run as
			print 'UNKNOWN: No username found in ' . $threshold_file;
			exit 3;
		} else {
			# All OK!
			return;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ' . $threshold_file . ' not found';
		exit 3;
	}
}




#----- parseOutput -----------------------------------------------------------
sub parseOutput {
	# This routine will vary considerably from script to script!
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		foreach my $proc (keys(%processes)) {
			if ($line =~ /$proc/) {
				$processes{$proc}++;
			}
		}
	}
	my @notrunning;
	while(my ($key,$val) = each(%processes)) {
		if ($val == 1) {
			push(@notrunning,$key);
		}
	}
	if (scalar(@notrunning > 0)) {
		$output = 'Not Running: ';
		foreach my $proc (@notrunning) {
			$output.= $proc.' ';
		}
		$return_code = 2;
	} else {
		$output = 'All Processes Running';
		$return_code = 0;
	}
	print $output;
	exit $return_code;
}




#----- main ------------------------------------------------------------------
getArgs();
readThresholds();
CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );
parseOutput();
