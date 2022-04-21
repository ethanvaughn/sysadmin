#!/usr/bin/perl

##############################################################################
#
# Purpose: 	Checks to see OAS is working according to opmnctl
#
# Note: This script logs-in directly as the 'username' user via ssh.
#       The 'username' parameter comes from the threshold file and defaults
#       to 'oas'. Copy the nagios user's id_dsa.pub key into authorized_keys
#       on the remote system.
#
# $Id: check_remote_oas.pl,v 1.12 2009/09/15 18:35:43 evaughn Exp $
# $Date: 2009/09/15 18:35:43 $
#
##############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use CheckBySSH;
use ArgParse;




#----- Globals ----------------------------------------------------------------
my %args;       # Where command-line arguments get stored
my $cmd;        # Comes directly from the 'opmn' property in thresholds file
my $basedir     = '/u01/home/nagios/monitoring';
my $optstr      = 'I:H:C:S:t:';
my $usage       = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds; # HashRef of properties from the threshold file.
my @required    = ( "username", "opmn", "services" );

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

# Build the services hash from the list of services in the threshold paremeter: 
my %services;
my @list = split( /,/, $thresholds->{services} );
if (scalar( @list ) > 0) {
	foreach my $service (@list) {
		# The value is a count that is incr while parsing output.
		# If we still have 0, this service wasn't found and we
		# return and error.
	    $services{$service} = 0; 
	}
}

# Note: for the command to succeed, the nagios user's ssh-key must be deployed
# to the remote user's authorized_keys. 
$cmd = "$thresholds->{opmn}";


# Make the call via SSH
CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}


# Parse the output: 
my @not_running;
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	# Check specifically for "Permission denied", which indicates running with the wrong user.
	if ( $line =~ /[Pp]ermission denied/ ) {
		print "Permission denied while executing command; check username parameter in file $threshold_file";
		exit 2;
	}

	# Check specifically for "No such file", which indicates the wrong path in the threshold file.
	if ( $line =~ /[Nn]o such file/ ) {
		print "Unable to execute opmnctl command; Check opmnctl path in file $threshold_file";
		exit 2;
	}

	my ($process,$status) = split( /\s+\|\s+/, $line );
	chomp( $status );

	if (exists( $services{$process} )) {
		$services{$process}++;

		if ($status =~ /Down/) {
			push( @not_running, $process );
		}
	}
}


if (scalar( @not_running ) > 0) {
	# Report on any servers in our list that are reported as 'Down'
	$result = 'Not Running: ';
	foreach my $service (@not_running) {
		$result .= $service . ' ';
	}
	print $result;
	exit 2;
}

my @not_found;
foreach my $service (keys( %services )) {
	if ($services{$service} == 0) {
		# Collect a list of services in our list that were not located 
		# in the output: 
		push( @not_found, $service );
	}
	if (scalar( @not_found ) > 0) {
		$result = 'Not Found: ';
		foreach my $service (@not_found) {
			$result .= $service . ' ';
		}

		print $result;
		exit 2;
	}
}

# Found all valid services, and all of them were running
print 'All Services Running';
exit 0;
