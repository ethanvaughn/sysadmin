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
my $cmd; # Will be constructed from the threshold property.
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( resultfile );

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

# Assemble the command based on the threshold property "resultfile".
cmd = 'cat' . " $thresholds->{resultfile}";

# Run the remote command and parse the output.
CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

# There should be only one line in the 'resultfile', but in case there are 
# multiple lines, this will return the results of the last line only.
# The format of the 'resultfile' :
#       resultcode|message
# Examples: 
#       2|SOD Failed: process not found
#       0|SOD completed successful
foreach my $line (@{$CheckBySSH::query_results{output}}) {
	my @values = split( /|/, $line );
}

print $values[1];
exit $values[0];
