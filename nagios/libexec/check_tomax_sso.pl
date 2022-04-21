#!/usr/bin/perl

#############################################################################
#
# Name: 	check_tomax_sso.pl
# Purpose:	Attempts to authenticate against Tomax SSO
#
# $Id: check_tomax_sso.pl,v 1.3 2009/05/29 05:08:56 evaughn Exp $
# $Date: 2009/05/29 05:08:56 $
#
#############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use URI;
use Getopt::Std;
use LWP::UserAgent;
use CheckLib;
use ArgParse;



#----- Globals ----------------------------------------------------------------
my %args;
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "username", "password", "port", "url" );

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


my $ua = LWP::UserAgent->new;
$ua->timeout($args{t});
my $url = URI->new('http://'.$args{I}.':'.$thresholds->{port}.$thresholds->{url});
$url->query_form(
	'invoke' => 'authenticateNE', # Part of the API for Tomax SSO
	'user' => $thresholds->{username},
	'password' => $thresholds->{password}
);
my $response = $ua->get($url);
if ($response->is_success) {
	if (${$response->content_ref} =~ /<return xsi:type="xsd:string">/) {
		$result = 'OK: SSO Authenticating Successfully';
		$return_code = 0;
	} elsif (${$response->content_ref} =~ /Authentication\+Failed/) {
		$result = 'CRITICAL: Invalid SSO Password (user:'.$thresholds->{username}.')';
		$return_code = 2;
	} else {
		$result = 'Unknown SSO Response';
		$return_code = 3;
	}
} else {
	$result = 'UNKNOWN: '.$response->status_line;
	$return_code = 3;
}
print $result;
exit $return_code;
