#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;
use lib::commandDirectory;
use lib::auth;
use CGI;


# Authenticate or die.
my $q = new CGI;
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


my @dir = ( "/u01/app/graphs/" );
lib::commandDirectory::readDirDatabase( @dir );
