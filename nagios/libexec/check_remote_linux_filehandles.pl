#!/usr/bin/perl

###############################################################################
#
# Purpose:	Checks the number of open filehandles on a Linux server
#		
#
# $Id: check_remote_linux_filehandles.pl,v 1.3 2009/05/22 22:12:55 evaughn Exp $
# $Date: 2009/05/22 22:12:55 $
#
###############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use CheckBySSH;
use ArgParse;




#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'cat /proc/sys/fs/file-nr ';
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "warning", "critical" );

# Output variables
my $result;
my $return_code;




#----- main -------------------------------------------------------------------
ArgParse::getArgs($optstr,5,\%args,\$usage);

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
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

my $match = 0;
my $used;
my $total;
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	if ($line =~ /(\d+)\s+\d+\s+(\d+)/) {
		$used = $1;
		$total = $2;
		$match = 1;
		last;
	}
}

if ($match) {
	my $percent_used = ($used/$total) * 100;
	if ($percent_used >= $thresholds->{warning}) {
		if ($percent_used >= $thresholds->{critical}) {
			# CRIT
			$return_code = 2;
		} else {
			# WARN
			$return_code = 1;
		}
	} else {
		$return_code = 0;
	}
	$result = sprintf('%d of %d filehandles used (%d%)|used:%d total:%d',$used,$total,$percent_used,$used,$total);
} else {
	$result = 'Unable to parse remote command: $cmd';
	$return_code = 3;
}


print $result;
exit $return_code;
