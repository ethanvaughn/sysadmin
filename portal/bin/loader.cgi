#!/usr/bin/perl

#############################################################################################################
#
#	What the heck is this?
#	Portal uses SSL.  The graphs shown in portal are not actually on this server,
#	and remote clients cannot talk directly to the server that generates the graphs.
#	Normally, mod_proxy would work great here (and does, as long as SSL is *NOT* used)
#	But, SSL requests cannot be proxied -- if it can work, it is more difficult to setup
#	than the below script, which regardless of the transport (HTTP/HTTPS) will proxy stuff.
#
#	For security measures, the URLs are hard-coded.  It will only proxy graph_image.php
#	or graph_xport.php, and it will rebuild the GET string passed to either.
#	Thus URLs will be of the following fomat to pass to this script:
#
#	loader.cgi?cgi=graph_image.php&action=view&local_graph_id=625&rra_id=1
#	
#	This in turn becomes:
#
#	graph_image.php?action=view&local_graph_id=625&rra_id=1
#
#	An obvious caveat is that if the target CGI (graph_image or graph_xport in this case)
#	has a key named CGI, the whole thing breaks.  Fortunately, neither CGI uses that variable
#	so we are safe.
#
#############################################################################################################

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;
use CGI;
use LWP::UserAgent;
use lib::auth;

my $base = 'http://10.24.74.35/cacti/';
my $q = new CGI;
my $cgi = $q->param('cgi');



# Authenticate or die.
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


if ($cgi eq 'graph_image.php' || $cgi eq 'graph_xport.php') {
	my $params = $q->Vars();
	delete($params->{cgi});
	my $param_string;
	while (my ($key,$val) = each(%$params)) {
		$param_string.= sprintf('%s=%s&',$key,$val);
	}
	chop($param_string);
	my $url = sprintf('%s%s?%s',$base,$cgi,$param_string);
	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);
	my $response = $ua->get($url);
	print $response->headers_as_string();
	print "\r\n";
	print $response->content();
} else {
	print 'Content-type:text/html',"\r\n\r\n";
	print 'Unable to process request';
}
