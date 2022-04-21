#!/usr/bin/perl

###############################################################
#
# Purpose:	Checks to see if given processes are running in the ps list. 
#
# $Id: check_remote_ps.pl,v 1.1 2010/02/19 20:27:41 evaughn Exp $
# $Date: 2010/02/19 20:27:41 $
#
###############################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;



#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd = 'ps -e -o user,comm,args'; #POSIX ps argument list 
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "procs" );

my %processes;

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

# Create a lookup table of processes to check:
foreach my $proc (split( /,/, $thresholds->{procs} )) {
	$processes{$proc} = 0;
}

if (exists( $thresholds->{user} )) {
	# Append user to the cmd:
	$cmd .= " | grep '^ *$thresholds->{user}'";
}


CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );
# This routine will vary considerably from script to script!
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

foreach my $line (@{$CheckBySSH::query_results{output}}) {
	foreach my $proc (keys(%processes)) {
		if ($line =~ /$proc/) {
			$processes{$proc}++;
		}
	}
}

my @notrunning;
while(my ($key,$val) = each(%processes)) {
	if ($val == 0) {
		push( @notrunning, $key );
	}
}

if (scalar( @notrunning > 0 )) {
	$result = 'Not Running: ';
	foreach my $proc (@notrunning) {
		$result .= $proc . ' ';
	}
	$return_code = 2;
} else {
	$result = 'All Processes Running';
	$return_code = 0;
}

print $result;
exit $return_code;
