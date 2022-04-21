#!/usr/bin/perl

###########################################################################################################
#
# Purpose: 		Tracks deltas between JPOS TXREP Connections over time
#			RUNS VIA CRON: This script is to be configured as a passive
#			check, but uses the same thresholds files as other checks.
#			Must run via cron due to excessive runtime length on some environments
#
# $Id: check_remote_txrep_connections.pl,v 1.3 2008/08/19 23:38:47 jkruse Exp $
# $Date: 2008/08/19 23:38:47 $
#
###########################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;
use PassiveCMD;

# Globals and configuration vars
my $optstr =		'I:H:C:S:t:';
my $basedir =		'/u01/home/nagios/monitoring';
my $tmpdir =            '/u01/app/nagios/tmp'; # Where to store the file containing the list of connections
my $usage =		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my %args;		# Where command-line arguments get stored
my $cmd;		# This will be built later
my $suffix;		# Determined on the fly
my $tmp_filename;	# Filename used for readings on this service

# Output variables
my ($output,$return_code);

# Function-specific variables
my %config;					# Configuration Directives (username,env_source,etc) go here
my (%current,%previous);
my ($gained_count,$lost_count,$current_count);

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t},$config{username});
parseOutput();

sub parseOutput {
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		my @values = split(/\s{2,}/,$line);
		foreach my $line (@values) {
			if ($values[1] =~ /^\d+$/ && exists($values[3])) {
				$current{$values[1]} = $values[3];
			} elsif ($line =~ /Total connections = (\d+)/i) {
				$current_count = $1;
			}
		}
	}
	if ($current_count > 0) {
		my $output_format = 'Gained: %d Lost: %d Current: %d|gained:%d lost:%d current:%d';
		my $full_filename = $tmpdir.'/'.$tmp_filename;
		if (-e $full_filename) {
			my $result = open(IN,$full_filename);
			if ($result) {
				while(<IN>) {
					if (/(\d+):(.*)/) {
						$previous{$1} = $2;
					}
				}
				close(IN);
				# Send the current hash back to the file we just read
				writeHashToFile($full_filename,\%current);
				# Now compare
				compareValues();
			} else {
				$output = sprintf('Unable to open %s for read, contact SA Team',$full_filename);
				$return_code = 3;
			}
		} else {
			if (writeHashToFile($full_filename,\%current)) {
				$output_format = '(No Previous Value) '.$output_format;
			}
		}
		# If $output has not yet been defined, then everything is OK.  Otherwise it has
		# already been set with an error that needs to be displayed
		if (!$output) {
			$output = sprintf($output_format,$gained_count,$lost_count,$current_count,$gained_count,$lost_count,$current_count);
			if ($config{warning} > 0 && $config{critical} > 0) {
				if ($gained_count >= $config{warning} || $lost_count >= $config{warning}) {
					if ($gained_count >= $config{critical} || $lost_count >= $config{critical}) {
						$return_code = 2;
					} else {
						$return_code = 1;
					}
				} else {
					$return_code = 0;
				}
			} else {
				$return_code = 0;
			}
		}
	} else {
		$output = 'Unable to parse TXREP Output';
		$return_code = 3;
	}
	# Service checks use the following format:
	#PROCESS_SERVICE_CHECK_RESULT;<host_name>;<service_description>;<return_code>;<plugin_output>
	my $cmd = sprintf('PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s',$args{H},$args{S},$return_code,$output);
	PassiveCMD::submit($cmd);
}

sub compareValues {
	# First compare all key / value pairs in $current to $previous
	# Any key/value pair present in $current and not in $previous represents a connection gain
	while (my ($key,$val) = each(%current)) {
		if (!(exists($previous{$key}) && $previous{$key} eq $val)) {
			$gained_count++;
		}
	}
	# Any key/value pair in $previous but not in $present represents a lost connection
	while (my ($key,$val) = each(%previous)) {
		if (!(exists($current{$key}) && $current{$key} eq $val)) {
			$lost_count++;
		}
	}
}

sub writeHashToFile {
	my ($file,$data) = @_;
	my $retval = 0;
	my $result = open(OUT,'>'.$file);
	if ($result) {
		while (my ($key,$val) = each(%$data)) {
			print OUT $key,':',$val,"\n";
		}
		close(OUT);
		$retval = 1;
	} else {
		$output = sprintf('Unable to open %s for write, contact SA Team',$file);
		$return_code = 3;
	}
	return $retval;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	$tmp_filename = $args{H}.'-'.$suffix;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	my $arg_count = 0;
	$config{warning} = 0;
	$config{critical} = 0;
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
			if (/txrep:(.*)/) {
				$config{txrep} = $1;
				$arg_count++;
				next;
			}
			if (/data_dir:(.*)/) {
				$config{data_dir} = $1;
				$arg_count++;
				next;
			}
			if (/^(warning|critical):(\d+)/) {
				$config{$1} = $2;
			}
		}
		close(FILE);
		if ($arg_count != 4) {
			print 'username,env_source,data_dir,txrep are required arguments';
			exit 3;
		} else {
			# All OK!
			# Build command before returning
			$cmd = "'source $config{env_source};cd $config{data_dir};$config{txrep} -ps'";
			return;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
