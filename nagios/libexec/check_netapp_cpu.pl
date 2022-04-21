#!/usr/bin/perl

use strict;
use Getopt::Std;

############################################################################################
#
# Purpose:	Checks NetApp CPU Usage
#
# $Id: check_netapp_cpu.pl,v 1.2 2008/02/25 04:51:34 jkruse Exp $
# $Date: 2008/02/25 04:51:34 $
#
############################################################################################

############################### Configuration Globals ######################################

my $snmpget = 		'/usr/bin/snmpget'; # The command to be run
my @args = 		qw(I); # Command-line arguments to parse (-I, -H...)

############################### Global Variables ##########################################

my $output;		# What the user (nagios) sees
my $return_code;	# Status code returned to the user (nagios)
my %args; 		# Command-line arguments go here
my $oid = 		'.1.3.6.1.4.1.789.1.2.1.3.0'; # OID to query
my $critical = 		90; # Critical threshold

############################### Main Body #################################################

getArgs();
queryOID();

############################### Functions #################################################


sub queryOID {
	my $cmd = sprintf('%s -v 1 -c public %s %s 2>&1|',$snmpget,$args{I},$oid);
	#print $cmd,"\n"; # Useful for debugging to see what monster command sprintf generates
	# Note that we are relying on snmpget's internal timeouts rather than an eval/die pair,
	# select/poll, etc.  snmpget appears to be reasonably reliable for this.
	my $result = open(CMD,$cmd);
	if (!$result) {
		printf('Unable to run %s:%s',$snmpget,$!);
		exit 3;
	} else {
		my $usage;
		while(<CMD>) {
			chomp;
			if (/:\s+(\d+)$/) {
				$usage = $1;
				last;
			} 
		}
		close(CMD);
		my $status = $?;
		$status >>= 8;
		if ($status != 0) {
			printf('Connection timed out querying %s',$args{I});
			exit 3;
		} else {
			# Return code from snmpget was zero, which means it didn't timeout, which is a good thing.
			# That does NOT mean, however, that our regex matched and we were able to extract the
			# value we wanted
			if (defined($usage)) {
				$output = sprintf('%d%%|%d',$usage,$usage);
				if ($usage >= $critical) {
					$return_code = 2;
				} else {
					$return_code = 0;
				}
			} else {
				$output = sprintf('Unable to read OID on %s',$args{I});
				$return_code = 3;
			}
		}
		print $output;
		exit $return_code;
	}
}

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

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -I <ip address>',
		"\n";
	exit 3;
}
