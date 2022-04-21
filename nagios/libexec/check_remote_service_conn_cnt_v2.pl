#!/usr/bin/perl

##############################################################################
#
#  Gather an aggregate connection count for the specified ports. Note: This
#  is an informational check that only returns CRITICAL / UNKNOWN from the 
#  underlying module, CheckBySSH
#
#  Author: Ethan Vaughn
#
##############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;



# ----- Globals --------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'netstat -an --tcp | grep ESTAB | grep '; # Command to run, the ports and "wc -l" will be appended in readThresholds
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required = ( 'ports' );

# Output variables
my $result;
my $return_code;

# Function-Specific variables
my $ports; # regex pattern of ports to get an aggregate connection count for, see readThresholds.
my %remote_hosts;




#----- Main ------------------------------------------------------------------
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

$cmd .= $thresholds->{ports};

# Run the remote command and parse the output.
CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}


my $count;

# Grab the count from the first line of the output array:
$count = $CheckBySSH::query_results{output}->[0];

$result = sprintf( '%d|%d', $count, $count );
$return_code = 0;

print $result;
exit $return_code;
