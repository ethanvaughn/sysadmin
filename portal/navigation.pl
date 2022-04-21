#!/usr/bin/perl
use strict;
use CGI;
use HTML::Template;
use CGI::Carp 'fatalsToBrowser';
use lib::auth;

#----- Globals ----------------------------------------------------------
my $q = new CGI;

# Get the cookie values
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );


#----- main --------------------------------------------------------------
# Authenticate or die.
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: login.html',"\n\n";
	exit 0;
}

my $q = new CGI;
my $username = $q->cookie("tomaxportalusername");
my $customer = $q->cookie("tomaxportalcustomer");
$customer = "\U$customer";
my $template;

print $q->header( "text/html" );
newTemplate('navigation', 'Navigation');
$template->param(customer => $customer, username => $username);
makeHTML();

sub newTemplate {
  my ($filename,$title) = @_;
  # Check to make sure we actually got a filename
  my $basedir = '/u01/app/portal/html';
  $template = HTML::Template->new(filename => $basedir.'/'.$filename.'.html', die_on_bad_params => 0, loop_context_vars => 1, global_vars => 1);
  $template->param(cgi => $q->url(-absolute=>1)); # CGI Script Name
  $template->param(title => $title);
}

sub makeHTML {
  # Close DB connection, we know we won't need it at this point
  # Set content type, allow caching
  print $template->output();
  exit 0;
}
