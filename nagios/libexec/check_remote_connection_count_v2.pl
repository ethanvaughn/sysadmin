#!/usr/bin/perl

#########################################################
#
# Purpose: 	Checks remote connection count
#		This is a purely informational check
#		that only returns critical / unknown
#		from the underlying module, CheckBySSH
# Author:  	Jake Kruse
# Version: 	1.0
# Date: 	09/19/2007
# Revision History:
#		1.0 - Initial Release
#
#########################################################


use lib '/u01/app/nagios/libexec/lib';

use strict;

use Socket; # For handling IP addresses

use CheckLib;
use ArgParse;
use CheckBySSH;




#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'netstat -n --numeric-ports --tcp';
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( );

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

# Validate the thresholds.
if (!exists( $thresholds->{network} )) {
	$bExclude = 0;
} else {
	$bExclude = 1;
	if (!exists( $thresholds->{netmask} )) {
		$thresholds->{netmask} = "255.255.255.0";
	}
	# Set numeric netmask to be used in calculations below ...
	$exclude_netmask = inet_aton( $thresholds->{netmask} );
}


# Run the remote command and parse the output.
CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	my @values = split(/\s+/,$line);
	if ($values[4] =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/) {
		# IP address sits in $1.
		if ($bExclude == 0) {
			# No exlusions from thresholds, log the IP.
			$remote_hosts{$1} = 1;
		} else {
			# If remote host's IP falls *outside* of the excluded subnet/netmask, add the IP to the remote_hosts hash.
			if (!(inet_ntoa(inet_aton($1) & $exclude_netmask) eq $thresholds->{network})) {
				$remote_hosts{$1} = 1;
			}
		}
	}
}

$count = scalar( keys( %remote_hosts ) );
$result = sprintf( '%d|%d', $count, $count );
$return_code = 0;

print $result;
exit $return_code;
