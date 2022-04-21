#!/usr/bin/perl

####################################################################################
#
# Purpose:	Checks memory usage on Linux servers
#
# $Id: check_remote_linux_mem.pl,v 1.3 2008/03/25 04:51:01 jkruse Exp $
# $Date: 2008/03/25 04:51:01 $
#
####################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use ArgParse;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'cat /proc/meminfo'; # Command to run, arguments and all (see below for more details on this)
my $optstr = 'I:t:';
my $usage = '-I <ip address> -t <timeout in seconds>',

# Output variables
my ($output,$return_code);

# Main Body
ArgParse::getArgs($optstr,2,\%args,\$usage);
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# This routine will vary considerably from script to script!
	my (%values,$memory_used);
	my $values_matched = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		if ($line =~ /^(MemTotal|MemFree|Buffers|Cached):\s+(\d+) kB$/) {
			$values{$1} = $2*1024; # Store each key & convert to bytes
			$values_matched++;
		}
		# If we have matched all 4 values, stop
		if ($values_matched == 4) {
			last;
		}
	}
	if ($values_matched == 4) {
		my $used = $values{MemTotal}-($values{MemFree}+$values{Buffers}+$values{Cached});
		my $f_used = prettyUp($used);
		my $f_cached = prettyUp($values{Cached});
		my $f_total = prettyUp($values{MemTotal});
		$output = sprintf('Used: %s Cached: %s Total: %s|used:%0.0f cached:%0.0f total:%0.0f',$f_used,$f_cached,$f_total,$used,$values{Cached},$values{MemTotal});
		$return_code = 0;
	} else {
		$output = 'UNKNOWN: Unable to read /proc/meminfo';
		$return_code = 3;
	}
	# After all is said and done, just spit out the output and use the exit code defined in return_code
	print $output;
	exit $return_code;
}

sub prettyUp {
	my $in = shift;
	if ($in =~ /\D/) {
		die "Invalid input: $in";
	}
	$in /= 1048576;
	my $suffix;
	if ($in > 1024) {
		$in /= 1024;
		$suffix = 'GB';
	} else {
		$suffix = 'MB';
	}
	return sprintf("%.2f \%s",$in,$suffix);
}
