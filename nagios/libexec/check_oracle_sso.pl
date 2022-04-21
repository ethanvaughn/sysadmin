#!/usr/bin/perl

#############################################################################
#
# Name: 	check_oracle_sso.pl
# Purpose:	Attempts to authenticate against Oracle's SSO and read
#		a SSO-protected URL
# Author:	Jake Kruse
# Date:		11/09/07
# Version:	2.0
# History:	
#		2.0 - 11/09/07 - Uses LWP (much cleaner)
#		1.0 - Who knows how long ago
#
#
#############################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use URI;
use LWP::UserAgent;
use Getopt::Std;
use CheckLib;
use ArgParse;



#----- Globals ----------------------------------------------------------------
my %args;
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "username", "password", "port", "url", "hostname" );

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


my $ua = LWP::UserAgent->new; # Create the web browser
my $req = HTTP::Request->new(GET => 'http://'.$args{I}.':'.$thresholds->{port}.$thresholds->{url}); # Create the request
$ua->timeout($args{t}); # Set the timeout
$ua->cookie_jar({}); # Turn on cookies and give it an in-memory temp cookie jar
$req->authorization_basic($thresholds->{username},$thresholds->{password});
$req->header(hostname => $thresholds->{hostname});
# Oracle's SSO supports basic HTTP authentication under the right circumstances, and LWP appears to be
# able to trick it into using it.  This is much easier than having to POST the credentials.  

# Were it not for Oracle's SSO supporting standard HTTP auth, it would be necessary to POST to the login page
# So there is no need at the present to enable following HTTP redirects from a POST.  If this changes
# in future releases, uncommmend this line, as LWP does not follow HTTP redirects from POST by default.
#push(@{$ua->requests_redirectable},'POST'); # Make it so LWP will follow redirects from HTTP POSTs
my $response = $ua->request($req);
if (!$response->is_success) {
	# The request failed.  This could be for a number of reasons, which need to be enumerated here.
	# Also it needs to be tested on 
	$result = 'UNKNOWN: '.$response->status_line;
	$return_code = 3;
} else {
	# It looks like it worked (no HTTP 500s, connection timeouts, etc.).  But Oracle often displays error pages
	# even when the HTTP status code is 200.  That's where test_string comes in handy.  If the resulting page contains
	# $thresholds->{test_string}, then it passes
	if (${$response->content_ref} =~ /$thresholds->{test_string}/) {
		$result = 'OK: Oracle SSO Authenticating,'.$thresholds->{url}.' responding';
		$return_code = 0;
	} else {
		# This could be anything
		$result = 'UNKNOWN: Unrecognized HTTP Response';
		$return_code = 3;
	}
}
print $result;
exit $return_code;
