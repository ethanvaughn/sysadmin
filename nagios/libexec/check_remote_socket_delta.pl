#!/usr/bin/perl

###########################################################################################################
#
# Purpose: 		Tracks deltas of socket connections for the specified source port
#			Uses netstat to examine the source port of the remote connection,
#			which will change if a client has disconnected and reconnected
#			since the last time the script executed
#
# $Id: check_remote_socket_delta.pl,v 1.3 2008/08/21 10:53:12 jkruse Exp $
# $Date: 2008/08/21 10:53:12 $
#
###########################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;

# Globals and configuration vars
my $optstr =		'I:H:C:S:t:';
my $basedir =		'/u01/home/nagios/monitoring';
my $tmpdir =            '/u01/app/nagios/tmp'; # Where to store the file containing the list of connections
my $usage =		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my $cmd	 = 		'/bin/netstat -n --numeric-ports --tcp';
my %args;		# Where command-line arguments get stored
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
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		my @values = split(/\s+/,$line);
		if ($values[3] =~ /:$config{port}$/ && $values[4] =~ /^(.*:\d+)/) {
			$current{$1} = 1;
			$current_count++;
		}
	}
	if ($current_count > 0) {
		my $output_format = 'Gained: %d Lost: %d Current: %d|gained:%d lost:%d current:%d';
		my $full_filename = $tmpdir.'/'.$tmp_filename;
		if (-e $full_filename) {
			my $result = open(IN,$full_filename);
			if ($result) {
				while(<IN>) {
					chomp;
					if (/(.*:\d+)/) {
						$previous{$1} = 1;
					}
				}
				close(IN);
				# Send the current hash back to the file we just read
				writeHashToFile($full_filename,\%current);
				# Now compare
				compareValues();
				# If either $gained_count or $lost_count are are over 90% of $current_count, discard the reading,
				# erase the previous value, and basically reset.  Better to have a gap in the graph
				# than a huge spike, which throws off all of the averages
				if ($gained_count/$current_count >= 0.9 || $lost_count/$current_count >= 0.9) {
					unlink($full_filename);
					$output = 'Change in gained/lost connections exceeded 90%, discarding';
					$return_code = 3;
				}
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
		$output = 'No Matching Connections Found';
		$return_code = 3;
	}
	print $output;
	exit $return_code;
}

sub compareValues {
	# Any key in $current and not in $previous represents a new connection (gain)
	foreach my $con (keys(%current)) {
		if (!exists($previous{$con})) {
			$gained_count++;
		}
	}
	# Any key in %previous and not in %present represents a closed connection (lost)
	foreach my $con (keys(%previous)) {
		if (!exists($current{$con})) {
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
			print OUT $key,"\n";
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
			if (/port:(\d+)/) {
				$config{port} = $1;
				$arg_count++;
				next;
			}
			if (/^(warning|critical):(\d+)/) {
				$config{$1} = $2;
			}
		}
		close(FILE);
		if ($arg_count != 1) {
			print 'port is a required argument, warning/critical are optional';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
