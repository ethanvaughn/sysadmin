#!/usr/bin/perl

###############################################################################
#
# Purpose:	Verifies if the given stage of TMX Credit Settlement has
#		completed or not by looking at the log files generated by
#		DBA scripts on the credit server.
#
# $Id: check_settlement_files.pl,v 1.1 2008/05/02 01:15:03 jkruse Exp $
# $Date: 2008/05/02 01:15:03 $
#
###############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;
use PassiveCMD;
use POSIX qw(setsid);

# Globals and configuration vars
my %args; 		# Where command-line arguments get stored
my $suffix;		# Determined on the fly
my $cmd =		'/bin/grep '; # Partially built, gets finished in readThresholds();
my $optstr =		'I:H:C:S:o:t:';
my $basedir =		'/u01/home/nagios/monitoring';
my $usage =		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name" -o <last ok time in unix epoch>',

# Output variables
my ($output,$return_code);

# Function-specific variables
my %config;

# Main Body

ArgParse::getArgs($optstr,6,\%args,\$usage);
readThresholds();
checkLastOKTime();
CheckBySSH::queryHost($cmd,$args{I},$args{t},$config{username});
parseOutput();

sub checkLastOKTime {
	# How this works:
	# 1) Get the time (in unix epoch) of today @ 12:00 AM
	# 2) If $args{o} is < today @ 12:00 AM, run resechdule
	# 	otherwise, run the service check
	my $today_midnight = `date -d 'today 12:00 AM' +\%s`;
	chomp($today_midnight);
	if ($args{o} < $today_midnight) {
		reschedule();
		printf('Next Check Scheduled at %s',$config{display_start_time});
		exit 0;
	}
}

sub parseOutput {
	if (exists($CheckBySSH::query_results{status_code})) {
		# This means the command timed out or the host barfed
		$output = $CheckBySSH::query_results{output};
		$return_code = $CheckBySSH::query_results{status_code};
	} elsif ($CheckBySSH::query_results{exit_code} != 0) {
		# This means that the command returned something other than zero,
		# which most likely means the file could not be found
		$output = sprintf('%s not found',$config{filename});
		$return_code = 2;
	} else {
		my $match_success = 0; # Boolean used to determine if match was successful
		foreach my $line (@{$CheckBySSH::query_results{output}}) {
			if ($line =~ /\|(\d+)/) {
				# This just means we were able to parse it.  Still don't know if
				# the data in the file is recent or not.  (This is field $1, unix epoch)
				# There are two ways to test that make the data in this file believeable
				# 1: is $1 > than $now? (current date in epoch)
				#	This applies to servers in different timezone than the monitoring
				#	server.  If the current time < $1, then this is new data and is OK.
				# 2: Is $1 the same day as today?
				# 	If this is true, it means this data is recent, at least within
				#	the last 24 hours.
				my $now = time();
				my @now = localtime($now);
				my @completed_time = localtime($1);
				if ($now < $1 || ($now - $1) < 86400) {
					# Woohoo! Recent data.  Grab the string tha says the operation
					# was successful, and convert the epoch time back to something
					# nice and display-able to the end-user
					$output = sprintf('%s (%s)',$config{match_string},scalar(localtime($1)));;
					$return_code = 0;
				} else {
					# The contents of this file were not created today.  That means the data is old and
					# someone should investigate why this file hasn't updated.
					$output = sprintf('%s was last modified %s',$config{filename},scalar(localtime($1)));
					$return_code = 2;
				}
				$match_success = 1;
				# We have found what we are looking for, do not parse this file any further
				last;
			}
		}
		# Now having exited the above loop, check if $match_success is still false.  If it is,
		# it means that the matching string could not be found
		if (!$match_success) {
			$output = sprintf('Unable to parse %s',$config{filename});
			$return_code = 3;
		} else {
			# If $return_code has a non-zero value, it means that the file is too
			# old and it hasn't been updated.  Thus we should alert and allow Nagios
			# to schedule the next service check as usual and not do any rescheduling voodoo
			if ($return_code == 0) {
				# Everything was OK (return code of zero).  In this case, fork off a child that will reschedule this
				# service to run at $config{start_time} instead of whatever the normal_check_interval
				# is for this service. 
				reschedule();
 				# Note after reschedule runs the parent will just come back to here
				# and keep running.
			}
		}
	}
	print $output;
	exit $return_code;
}

sub reschedule {
	# This function should only be called by the child process after fork()ing, and no other time!
	# First we need to know the time of tomorrow @ midnight to start.  Best way to get this is from
	# the date command.
	my $pid = fork();
	if ($pid == 0) {
		# This is the child process
		# Detach from parent and become a session leader
		setsid();
		# Sleep for a bit to let Nagios process the service check result
		# of the parent
		sleep(15);
		my $next_check_time = `date -d 'tomorrow 12:00 AM' +\%s`;
		chomp($next_check_time);
		if ($next_check_time =~ /^(\d+)$/) {
			$next_check_time+= $config{start_time};
			# Now build the command along the lines of the following example:
			# SCHEDULE_FORCED_SVC_CHECK;host1;service1;1110741500
			my $cmd = sprintf('SCHEDULE_FORCED_SVC_CHECK;%s;%s;%d',$args{H},$args{S},$next_check_time);
			# Now hand this off to PassiveCMD::submit
			PassiveCMD::submit($cmd);
			# Do not continue running: exit from here immediately.
			exit 0;
		}
	} else {
		# This is the parent process: just return and go back to work
		return;
	}
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	# Before reading in the parameter file, read in the OCSP data
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^username:(.*)/) {
				$config{username} = $1;
				$arg_count++;
				next;
			}
			if (/^filename:(.*)/) {
				$config{filename} = $1;
				$arg_count++;
				next;
			}
			if (/^match_string:(.*)/) {
				$config{match_string} = $1;
				$arg_count++;
				next;
			}
			if (/start_time:(\d{2}):(\d{2})/) {
				# Validate that this is a valid military time (00:00)
				if ($1 >= 0 && $1 < 24 && $2 >= 0 && $2 < 60) {
					# Convert HH:MM format to seconds
					my $secs = ($1*3600)+($2*60);
					$config{start_time} = $secs;
					$config{display_start_time} = sprintf('%s:%s',$1,$2);
					$arg_count++;
				}
			}
		}
		close(FILE);
		if ($arg_count != 4) {
			# Insufficient arguments
			print 'username,filename,match_string,start_time (HH:MM format) are requred arguments';
			exit 3;
		} else {
			# Finish the command
			# Note that the pipe needs to be escaped, otherwise CheckBySSH will interpret
			# it as the end of the command, and omit the remainder of the command line
			# that gets passed to SSH
			$cmd.= sprintf('"%s" %s',$config{match_string},$config{filename});
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
