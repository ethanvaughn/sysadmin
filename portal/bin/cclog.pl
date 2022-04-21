#!/usr/bin/perl -w

use FindBin qw( $Bin );
use lib "$Bin/..";

use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use HTML::Template;

use dao::saconnect;
use lib::cclog;
use lib::auth;


use strict;


#---- Globals ----------------------------------------------------------------
my $q = new CGI;
my $username = $q->cookie("tomaxportalusername");
my $password = $q->cookie("tomaxportalpassword");
my $customer = $q->cookie("tomaxportalcustomer");
my $ucustomer = "\U$customer";
my $htmlview = "";
my $msg = "";


#---- Main -------------------------------------------------------------------
# Authenticate or die.
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}


# CONNECT To The Database
my $dbh = dao::saconnect::connect();

# Get cclog data for this customer:
my $data = lib::cclog::getCCLog( $dbh );

dao::saconnect::disconnect( $dbh );

# DEBUG
print STDERR "data = $data\n";
print STDERR "data[0] = $data->[0]{time}\n";

# Set up the view:
$htmlview = HTML::Template->new( filename => "../html/cclog.html", loop_context_vars => 1 );
$htmlview->param( title => "CC View Log" );
$htmlview->param( username => $username );
$htmlview->param( cclog => $data );


print header;
print $htmlview->output;

exit (0);

