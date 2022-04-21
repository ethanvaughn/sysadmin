#!/usr/bin/perl

#############################################################################################################
#
# Purpose: 	Checks to to see how many procs are running that contain
#		the given string found in the threshold file
#
# $Id: check_remote_process_count_v2.pl,v 1.1 2010/04/13 20:51:02 evaughn Exp $
# $Date: 2010/04/13 20:51:02 $
#
#############################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;


#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd =  'pgrep -f '; # Command to run, process name will be added later
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( 'procname' );

# Output variables
my $result;
my $return_code;


# Function-Specific variables
my $bExclude = 1;
my $exclude_netmask;
my $count = 0;
my %remote_hosts;




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

# Build the command: 
$cmd .= $thresholds->{procname};

# Run the remote command and parse the output.
CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}
my $count = 0;
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	$count++;
}
$result = sprintf('%d|%d',$count,$count);
$return_code = 0;
print $result;
exit $return_code;
