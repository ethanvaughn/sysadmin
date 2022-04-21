#!/usr/bin/perl

########################################################################################
#
# Purpose: 	Checks swap usage on Linux systems
#
# $Id: check_remote_linux_swap.pl,v 1.7 2009/05/22 22:12:55 evaughn Exp $
# $Date: 2009/05/22 22:12:55 $
#
########################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;



#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'cat /proc/meminfo'; # Command to run, arguments and all (see below for more details on this)
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "warning", "critical" );

# Output variables
my $result;
my $return_code;




#----- main -------------------------------------------------------------------
ArgParse::getArgs( $optstr, 5, \%args, \$usage );

# Piece-together the name of the thresholds and default files from args:
my $serv_desc = CheckLib::normalizeServDesc( $args{S} );
my $threshold_file = "$basedir/$args{C}/$args{H}-$serv_desc";
if (! -e $threshold_file) {
	# No thresholds file, try default:
	$threshold_file = "$basedir/default/$serv_desc";
}

# Load threshold properties:
$thresholds = CheckLib::loadThresholds( $threshold_file, \@required );
if ($thresholds->{result} ne "0|OK") {
	($return_code,$result) = split( /\|/, $thresholds->{result} );
	print $result;
	exit $return_code;
}

CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );


# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
# the amount of data processing should be kept to a minimum
my %values;
my $values_matched = 0;

if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

foreach my $line (@{$CheckBySSH::query_results{output}}) {
	if ($line =~ /^(SwapTotal|SwapFree):\s+(\d+) kB$/) {
		$values{$1} = $2;
	}
	# If we have matched two values ($match_count == 2) then we are done and can move onto the next step
	if (exists( $values{SwapTotal} ) && exists( $values{SwapFree} )) {
		$values_matched = 1;
		last;
	}
}

if ($values_matched) {
	my ($swap_used,$percent_used);
	my $percent_used;
	# Check and see is swap_used is zero or not to prevent divide by zero
	if ($values{SwapTotal} == $values{SwapFree}) {
		$swap_used = 0;
		$percent_used = 0;
	} else {
		$swap_used = $values{SwapTotal} - $values{SwapFree};
		$percent_used = ($swap_used/$values{SwapTotal})*100;
		
	}
	# Compare against thresholds
	if ($percent_used >= $thresholds->{critical}) {
		$return_code = 2;
	} elsif ($percent_used >= $thresholds->{warning}) {
		$return_code = 1;
	} else {
		$return_code = 0;
	}

	# Append the actual amount of swap and perf data
	$result .= sprintf( '%d%% Used (%d MB used,%d MB total)|%0.f', $percent_used, $swap_used/1024, $values{SwapTotal}/1024, $swap_used*1024 );
} else {
	$result = 'UNKNOWN: Unable to read /proc/meminfo';
	$return_code = 3;
}


print $result;
exit $return_code;

