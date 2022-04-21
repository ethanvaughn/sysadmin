#!/usr/bin/perl

###############################################################################################
#
# Purpose: Checks to see if Otranpost is working properly
#
# $Id: check_remote_otranpost.pl,v 1.5 2009/03/26 19:51:22 evaughn Exp $
# $Date: 2009/03/26 19:51:22 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckLib;
use ArgParse;
use CheckBySSH;

# Globals and configuration vars
my %args;		# Where command-line arguments get stored
my $cmd;		# This will be built later
my $suffix;		# Determined on the fly
my $optstr =		'I:H:C:S:t:';
my $usage =		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my $basedir =		'/u01/home/nagios/monitoring';

# Output variables
my ($output,$return_code);

# Function-specific variables
my %config;

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t},$config{username});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	# There are two pieces of info to check:
	# 1) is otranpost running?
	# 2) how many transactions are waiting to be posted?
	my $otranpost_running = 0;
	my $transactions_waiting = undef;
	my $transactions_posted = undef;
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /^TRANPOST.*is running/) {
			$otranpost_running = 1;
			next;
		}
		# Depending on which version of JPOS is installed, the JPOS developers like to keep us guessing
		# on the output of JPOS.  Most Linux versions seems to say submit/submitted, while Solaris versions say post.
		# Note the use of non-capturing groups to speed this up somewhat.  The number of transactions ends 
		# up in $1, not $2, since the first RE is non-capturing (see the perlretut man page, non-capturing 
		# groups for more on this)
		#if ($line =~ /^Number of transactions left to (?:submit|post): (\d+)$/) {
		if ($line =~ /ransactions left to (?:submit|post): (\d+)$/) {
			$transactions_waiting = $1;
			next;
		}
		#if ($line =~ /^Total # of transactions (?:submitted|posted): (\d+)/) {
		if ($line =~ /ransactions (?:submitted|posted): (\d+)/) {
			$transactions_posted = $1;
			next;
		}
	}
	# Now that the values have been extracted, let's parse them and do a little logic
	if ($otranpost_running) {
		# Next step: did otranpost respond back with the number of transactions waiting?
		if (defined($transactions_waiting)) {
			# We know the command completed OK, but have we breached any thresholds?
			if ($transactions_waiting >= $config{critical}) {
				$return_code = 2;
			} elsif ($transactions_waiting >= $config{warning}) {
				$return_code = 1;
			} else {
				$return_code = 0;
			}
			$output = sprintf('%d Transactions Pending|pending:%d',$transactions_waiting,$transactions_waiting);
			if (defined($transactions_posted)) {
				$output.= sprintf(' submitted:%d',$transactions_posted);
			}
		} else {
			$output = 'Unknown transaction count pending';
			$return_code = 3;
		}
	} else {
		# If otranpost isn't running, who cares how many transactions are backed up.  They'll never post
		# as long as it isn't running
		$output = 'Not running';
		$return_code = 2;
	}
	print $output;
	exit $return_code;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found

	$suffix = CheckLib::normalizeServDesc( $args{S} );
	my $threshold_file = "$basedir/$args{C}/$args{H}-$suffix";

	my $result = open( FILE, $threshold_file );
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/username:(.*)/) {
				$config{username} = $1;
				$arg_count++;
				next;
			}
			if (/env_source:(.*)/) {
				$config{env_source} = $1;
				$arg_count++;
				next;
			}
			if (/data_dir:(.*)/) {
				$config{data_dir} = $1;
				$arg_count++;
				next;
			}
			if (/otranpost:(.*)/) {
				$config{otranpost} = $1;
				$arg_count++;
				next;
			}
			if (/(warning|critical):(\d+)$/) {
				$config{$1} = $2;
				$arg_count++;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 6) {
			# This means we didn't get any valid partitions to check
			print 'username,env_course,data_dir,otranpost are requred arguments';
			exit 3;
		} else {
			# All OK!
			# Build command before returning
			$cmd = "'source $config{env_source};cd $config{data_dir};$config{otranpost} -stats'";
#open( TMP, ">/tmp/otran.cmd" );
#print TMP $cmd;
#close TMP;
			return;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ' . $threshold_file . ' not found';
		exit 3;
	}
}
