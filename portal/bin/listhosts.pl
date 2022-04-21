#!/usr/bin/perl

# Libraries to use for this script
use strict;

use FindBin qw( $Bin );
use lib "$Bin/..";

use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

use lib::auth;
use lib::URLQuery;
use lib::createHTML;


#----- Globals ----------------------------------------------------------
my $q = new CGI;

# Get the cookie values
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );


#----- main --------------------------------------------------------------
# Authenticate or die.
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}



my @dataset;
my $url = sprintf( 'listhosts?info=1&cust=%s', $cust );

my $raw_data = lib::URLQuery::fetchURL($url);
my @lines = split(/\r\n|\n/,$$raw_data);

foreach my $line(@lines) {
	my %hosthash;
	my @hostinfo = split( /,/, $line );
	$hostinfo[2] =~ s/uc($cust)//;

	$hosthash{ 'hostname' } 			= $hostinfo[0];
	$hosthash{ 'ip_address' } 			= $hostinfo[1];
	$hosthash{ 'description' } 			= $hostinfo[2];
	$hosthash{ 'host_status' } 			= $hostinfo[3];

	if ( $hostinfo[3] eq "0" ) {
		$hosthash{ 'host_up' } = 1;
	}

	if ( $hostinfo[3] eq "1" || $hostinfo[3] eq "2" ) {
		$hosthash{ 'host_critical' } = 1;
	}

	if ( $hostinfo[4] eq "0" ) {
		$hosthash{ 'service_up' } = 1;
	}
	if ( $hostinfo[4] eq "1" ) {
		$hosthash{ 'service_warning' } = 1;
	}
	if ( $hostinfo[4] eq "2" || $hostinfo[4] eq "3" ) {
		$hosthash{ 'service_critical' } = 1;
	}

	$hosthash{ 'host_ack' } 				=	$hostinfo[5];
	$hosthash{ 'serv_ack' }					= $hostinfo[6];
	$hosthash{ 'host_maintenance' }	= $hostinfo[7];
	$hosthash{ 'serv_maintenance' } = $hostinfo[8]; 

	push ( @dataset, \%hosthash );
}



lib::createHTML::newTemplate( 'listhosts', 'Server Status', [ $q, \@dataset, $username ] );

