#!/usr/bin/perl

##########################################################
#
# Purpose: Checks CPU Usage via SAR (RHEL3 and later ONLY)
#
# $Id: check_remote_linux_cpu.pl,v 1.6 2009/11/10 22:41:32 evaughn Exp $
# $Date: 2009/11/10 22:41:32 $
#
##########################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use CheckBySSH;
use ArgParse;




#----- Globals ----------------------------------------------------------------
my %args;  # Where command-line arguments get stored
my $cmd    = 'sar -P ALL 1 10 | grep -i ^average'; # Command to run, arguments and all
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( );

# Output variables
my $result;
my $return_code;

# Function-specific variables
my @cpus;
my $total_average;




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

# Ignore threshold errors and set defaults if necessary: 
if (!exists( $thresholds->{cpu} )) {
	$thresholds->{cpu} = '99';
}


CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

# Gather the CPU metrics:
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	if ($line =~ /^average:\s+(all|\d+).*\s+(\d{1,2}\.\d{1,2})$/i) {
		if (lc($1) eq 'all') {
			$total_average = 100-$2;
		} else {
			$cpus[$1] = sprintf('%.2f',100-$2);
		}
	}
}


# Check for runaway procs (see if any CPU is above the threshold and alert)
#foreach my $cpu (@cpus) {
for (my $i=0; $i<($#cpus+1); $i++) {
	if ($cpus[$i] >= $thresholds->{cpu}) { 
		print "cpu[$i] = $cpus[$i]\n";
		$result = sprintf( 'Critical: CPU[%d] at %d% (threshold set to %d%). Check for runaway process.|%d', 
			$i, 
			$cpus[$i], 
			$thresholds->{cpu}, 
			$total_average );
		print $result;
		exit 2;
	}
}


# Report the metrics:
$result = sprintf( 'CPU Average %d%|%d', $total_average, $total_average );
print $result;
exit 0;

