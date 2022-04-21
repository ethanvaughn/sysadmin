#!/usr/bin/perl

###############################################################################
#
# Purpose:	Counts the number of files in a directory and checks against
#		the defined threshold
#
# $Id: check_remote_linux_file_count_v2.pl,v 1.1 2009/07/15 22:05:12 evaughn Exp $
# $Date: 2009/07/15 22:05:12 $
#
###############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;




#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'ls -A1 ';
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( );

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

# Set defaults for missing properties:
if (!exists( $thresholds->{directory} )) {
	$thresholds->{directory} = '/u01/app/tomax/data/trandir';
}
if (!exists( $thresholds->{username} )) {
	$thresholds->{username} = 'tomax';
}


# Finish the cmd:
$cmd .= $thresholds->{directory} . ' \| wc -l';


CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );


# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
# the amount of data processing should be kept to a minimum
# This routine will vary considerably from script to script!
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}
my $count;
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	if ($line =~ /(\d+)/) {
		$count = $1;
		last;
	}
}

if ($count) {
	$result = sprintf( '%d File(s) in %s|%d', $count, $thresholds->{directory}, $count );
	if ($count > $thresholds->{count}) {
		$return_code = 2;
	} else {
		$return_code = 0;
	}
} else {
	$result = sprintf( 'Unable to read file count in %s', $thresholds->{directory} );
	$return_code = 3;
}

print $result;
exit $return_code;
