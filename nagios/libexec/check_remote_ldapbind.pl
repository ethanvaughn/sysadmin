#!/usr/bin/perl

####################################################################################
#
# Purpose:	
#
# $Id: check_remote_ldapbind.pl,v 1.2 2009/04/10 19:41:23 evaughn Exp $
# $Date: 2009/04/10 19:41:23 $
#
####################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use CheckBySSH;
use ArgParse;



#----- Globals ---------------------------------------------------------------
my $usage           = '-C <customer abbrev> -H <hostname> -I <ip address> -S "Service Description" [-t <timeout in seconds>]';
my $optstr          = 'C:H:I:S:t:';
my %args;           # hash containing commandline args (see getArgs())
my $threshold_file  = '/u01/home/nagios/monitoring'; # Built from command-line args
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "ENV", "LDAPBIND", "PORT", "CN", "PASSWORD" );
my $cmd;            # the command to pass through to ssh, arguments and all (usu. built from threshold properties).
my $result          = "UNKNOWN";
my $return_code     = 3;


#----- main ------------------------------------------------------------------
ArgParse::getArgs( $optstr, 5, \%args, \$usage );

# Piece-together the name of the thresholds file:
my $serv_desc = CheckLib::normalizeServDesc( $args{S} );
$threshold_file .= "/$args{C}/$args{H}-$serv_desc";

# Load threshold properties:
$thresholds = CheckLib::loadThresholds( $threshold_file, \@required );
if ($thresholds->{result} ne "0|OK") {
	($return_code,$result) = split( /\|/, $thresholds->{result} );
	print $result;
	exit $return_code;
}


# Build the command:
# eg: "source ./oasmt.cfg; /u01/app/10g/oasmt/bin/ldapbind -p 3060 -D cn=orcladmin -w manager1"
$cmd = "'source " . $thresholds->{ENV} . "; " .
	$thresholds->{LDAPBIND} .
	" -p " . $thresholds->{PORT} .
	" -D cn=" . $thresholds->{CN} .
	" -w " . $thresholds->{PASSWORD} .
	"'";

# Execute the remote command
CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );

# Parse the output
if (exists( $CheckBySSH::query_results{status_code} )) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

# Inspect the last line and return result.
my $i = (@{$CheckBySSH::query_results{output}} - 1);
$result = @{$CheckBySSH::query_results{output}}[$i];
if ($result =~ /[Bb]ind.*[Ss]ucce/) {
	# Set to OK
	$return_code = 0;
} else {
	# Set to CRIT
	$return_code = 2;
}


print $result;
exit $return_code;
