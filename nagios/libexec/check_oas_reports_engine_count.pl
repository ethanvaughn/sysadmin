#!/usr/bin/perl

###############################################################################################
#
# Name:		check_oas_reports_engine_count.pl
# Purpose:	Counts the number of OAS reports servers running
#
# $Id: check_oas_reports_engine_count.pl,v 1.5 2009/04/10 19:40:03 evaughn Exp $
# $Date: 2009/04/10 19:40:03 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use URI;
use ArgParse;
use CheckLib;
use LWP::UserAgent;




#----- Globals and configuration vars ----------------------------------------
my $usage           = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my $optstr          = 'I:H:C:S:t:';
my %args;           # Where command-line arguments get stored
my $threshold_file  = '/u01/home/nagios/monitoring'; # Built from command-line args
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "PORT", "URL", "ENGINE_COUNT" );
my $result          = "UNKNOWN";
my $return_code     = 3;




#----- main ------------------------------------------------------------------
ArgParse::getArgs($optstr,5,\%args,\$usage);

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


# Query the URL and parse the output.
my $ua = LWP::UserAgent->new;
my $req;
# In case the host is very sensitive about the HTTP headers it gets, if the port is 80,
# just create a normal HTTP request without specifying the port number.
print STDERR "URL = $thresholds->{URL}\n";
if ($thresholds->{PORT} == 80) {
	$req = HTTP::Request->new( GET => 'http://' . $args{I} . $thresholds->{URL} );
} else {
	$req = HTTP::Request->new( GET => 'http://' . $args{I} . ':' . $thresholds->{PORT} . $thresholds->{URL} );
}
$ua->timeout( $args{t} ); # Set the timeout
$ua->cookie_jar( {} ); # Turn on cookies and give it an in-memory temp cookie jar
# Some application servers need the hostname sent back to them in the header,
if (exists( $thresholds->{HOSTNAME} )) {
	$req->header( hostname => $thresholds->{HOSTNAME} );
}
my $response = $ua->request( $req );
if (!$response->is_success) {
	# Request failed.  Could be for a whole garden variety of reasons (404, conection refused, etc. etc. etc.)
	$result = sprintf( 'UNKNOWN: %s', $response->status_line );
	$return_code = 3;
} else {
	my $engines_running;
	foreach my $line (split( /\n/, ${$response->content_ref} )) {
		if ($line =~ /engineInstance name="rwEng/) {
			$engines_running++;
		}
		if ($line =~ /REP-/) {
			# This is an error condition...
			print "UNKNOWN: $line";
			exit 3;
		}
	}
	if (defined( $engines_running )) {
		if ($engines_running < $thresholds->{ENGINE_COUNT}) {
			$return_code = 2;
		} else {
			$return_code = 0;
		}
		$result = sprintf( '%d Engines Running|%d', $engines_running, $engines_running );
	} else {
		# This is a special case. Apparently at random times Oracle simply
		# fails (or refuses) to report the number of running rep engines. 
		# Since we can't do anything about this, there is no point in 
		# alerting on it.
		$result = 'No engines found';
		$return_code = 0;
	}
}

print $result;
exit $return_code;
