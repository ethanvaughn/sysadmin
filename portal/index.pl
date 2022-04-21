#!/usr/bin/perl
# index.pl
# Grab the username and password from the form
# If the username and password authenticate against the database, send the user
# to their portal page

use strict;

use CGI;
use DBI;
use HTML::Template;

use lib::auth;


## DoS Protection                                                              
$CGI::POST_MAX=1024 * 100; # max 100K posts 
$CGI::DISABLE_UPLOADS = 1; # no uploads


#----- Globals ----------------------------------------------------------------
my $q = new CGI;
my $template;


my $username = $q->param('username');
my $password = $q->param('password');
my $cust;

print STDERR "from POST: user = $username ... passwrd = $password\n";

# If the username is not set from the HTML form, check to see if a cookie is set
if (!$username) {
	($username, $password, $cust) = lib::auth::getCookieValues( $q );
}

# If the cookie is not set or expired, then send the user to the login page
if (!$username) {
	print 'Location: login.html',"\n\n";
	exit 0;
} else {
		my $cust;
		$cust = lib::auth::isValidUser( $username, $password );
		if ($cust) {
			my $setUsername = $q->cookie(-name => 'tomaxportalusername',
					-value => $username,
					-expires => '+1d',
					-path => '/');
			my $setPassword = $q->cookie(-name => 'tomaxportalpassword',
					-value => $password,
					-expires => '+1d',
					-path => '/');
			my $setCustomer = $q->cookie(-name => 'tomaxportalcustomer',
					-value => $cust,
					-expires => '+1d',
					-path => '/');
			print $q->header(-cookie => [$setUsername, $setPassword, $setCustomer]);
print STDERR "     index.pl: set cookies -- $setUsername, $setPassword, $setCustomer\n";
			newTemplate('main','Main');
			makeHTML();
		} else {
			print 'Location: /portal/login.html',"\n\n";
			exit 0;
		}
}




sub newTemplate {
  my ($filename,$title) = @_;
  my $basedir = '/u01/app/portal/html';
  $template = HTML::Template->new(filename => $basedir.'/'.$filename.'.html', die_on_bad_params => 0, loop_context_vars => 1, global_vars => 1);
  $template->param(cgi => $q->url(-absolute=>1)); # CGI Script Name
  $template->param(title => $title);
}




sub makeHTML {
  # Close DB connection, we know we won't need it at this point
  print $template->output();
  exit 0;
}
