#!/usr/bin/perl -w

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use CGI::Session;
use JSON;

use lib::conf;
use lib::auth;
use lib::notifications;


#---- Globals ----------------------------------------------------------------
my $CGI       = new CGI;
my $self_url  = $CGI->url(-absolute => 1);
my $vars      = $CGI->Vars;

# Attempt to load session from the cookie:
my $SESSION = CGI::Session->new( undef, $CGI );

# Set convenience variables from POST and GET values: 
# Note: AUTH states: 0/undef: this is not an authentication request.
my $AUTH       = $vars->{auth} if (exists( $vars->{auth} ));
my @ACTION_SET = $CGI->param( 'action_set' );
my @ACTION_GET = $CGI->param( 'action_get' );
# RESPONSE: HoH that will hold all data structures to be translated to json 
# for response to the client.
my %RESPONSE;
$RESPONSE{hPortal} = {};




#----- appendError ---------------------------------------------------------------
# Helper function to append an error struct to send back to client.
sub appendError {
print STDERR "appendError()\n";
	my $msg = shift;

	# Error ID is epoch prefixed with 'E'
	my $EID       = 'E' . time();
	my $timestamp = localtime();

	print STDERR $EID . " " . $msg . "\n";

	$RESPONSE{hPortal}{error} = {
		timestamp => $timestamp,
		eid       => $EID,
		msg       => $msg
	};
}




#----- auth_error ---------------------------------------------------------------
# Helper function to clean up prior to exit on auth error.
# Invalidate session, send user to the log in screen.
sub auth_error {
print STDERR "auth_error()\n";
	if ($CGI->param( 'TEST' )) {
		print $CGI->header( -type=>'text/plain' );
	} else {
		print $CGI->header( -type=>'application/json' );
	}
	
	print '{"loginPage":{';
	if ($AUTH && $AUTH eq 1) {
		# Use parameter "auth=0" to suppress error message (eg. during "logout")
		print '"error":{"timestamp":"' . localtime() . '","msg" : "Invalid login. Please try again."}';
	}
	print '}}';

	$SESSION->delete();
	$SESSION->flush();

	exit (0);
}




#---- Main -------------------------------------------------------------------
if ($AUTH eq 0) {
	auth_error();
}

if ($AUTH) {
	# Invalidate the session.
	$SESSION->delete();
	$SESSION->flush();
	
	# Check for critical data.
	if (!$vars->{username}) {
		print STDERR "Unable to authenticate: username parameter missing.\n";
		auth_error();
	}
	
	# Authenticate
	if (!lib::auth::authenticate( $vars->{username}, $vars->{password} )) {
		print STDERR "Authentication failure for user: [$vars->{username}]\n";
		auth_error();
	}

	# Auth succeeded, create a new session.
	$SESSION = CGI::Session->new();
	if (!$SESSION) {
		print STDERR "Unable to create new session: " . CGI::Session->errstr() . "\n";
		auth_error();
	}
	
	# Populate the session from external datasources.
	lib::auth::initSession( $SESSION, $vars->{username} );
	$SESSION->flush();

	# Now that the session is initialized, specify the datasets 
	# based on the user's group.
	if (lib::auth::isAdminUser( $SESSION->param( 'group' ) )) {
		@ACTION_GET = ( 'custs', 'profile' );
		if ($SESSION->param('cust_code')) {
			push( @ACTION_GET, 'hosts' );
			push( @ACTION_GET, 'notifications' );
		}
	} else {
		# Customer user
		# Failsafe: always set the cust_code variable to the group name constant;
		$SESSION->param( 'cust_code', $SESSION->param( 'group' ) ); 
		@ACTION_GET = ( 'hosts', 'notifications', 'profile'  );
	}
}


# Validate. Note: this catches the logout case.
if (!lib::auth::validateSession( $CGI, $SESSION )) {
	auth_error();
}

print STDERR "DEBUG .. SESSION->id1 = " . $SESSION->id . "\n";

# Now that the session is validated, restart the http response.
# This saves the new session id on the cookie. 
if ($vars->{TEST}) {
	print $SESSION->header( -type=>'text/plain' );
} else {
	print $SESSION->header( -type=>'application/json' );
}




#---- "SET" Action Processor Engine ------------------------------------------------------
if (@ACTION_SET > 0) {
	my $LEN = (@ACTION_SET - 1);
	for (my $i=0; $i < @ACTION_SET; $i++) {

		#===== Updates available only to privileged users ======
		if (lib::auth::isAdminUser( $SESSION->param( 'group' ) )) {

			#-----  --------------------------------------------
			# Update the list of customers to select from. Available only to admin users.
			#if ($ACTION_SET[$i] eq 'custs') {
				# custs = getCusts
				# Append new record
				# setCusts( custs )
			#}
		}




		#===== Updates available to all  users =================
		if ($ACTION_SET[$i] eq 'profile') {
			if ($vars->{profile}) {
				my $profile = from_json( $vars->{profile} );
				my $cust_name = lib::auth::lookupCustName( $profile->{cust_code} );
				$profile->{cust_name} = $cust_name;

				# Create a hash of the writable items.
				my $writable;
				if (lib::auth::isAdminUser( $SESSION->param( 'group' ) )) {
					# Admin-only items:
					$writable->{cust_code} = $profile->{cust_code};
					# Update the admin-only items in the session.
					$SESSION->param('cust_code', $profile->{cust_code} );
					$SESSION->param('cust_name', $profile->{cust_name} );
				}

				# Add non-privileged items here:
				$writable->{host_table_width} = $profile->{host_table_width};
				$SESSION->param('host_table_width', $profile->{host_table_width} );
				
				# Persist the writable profile items to external datastores.
				if (!lib::auth::setProfile( $SESSION->param('username'), $writable )) {
					appendError( "main::action_set[profile]  Error writing profile for user " . $SESSION->param('username') . ": $!" );
				}
			} else {
				appendError( "main::action_set[profile]  Parameter 'profile' missing for user " . $SESSION->param('username') . ": $!" );
			}
		} #profile

	} #for
}
#----- END "SET" Processor Engine -------------------------------------------------




#---- "GET" Action Processor Engine ------------------------------------------------------
if (@ACTION_GET > 0) {
	my $LEN = (@ACTION_GET - 1);
	for (my $i=0; $i < @ACTION_GET; $i++) {


		#===== Datasets available only to privileged users ======
		if (lib::auth::isAdminUser( $SESSION->param( 'group' ) )) {

			#----- custs --------------------------------------------
			# List of customers to select from. Available only to privileged (non-cust) users.
			if ($ACTION_GET[$i] eq 'custs') {
				$RESPONSE{hPortal}{custs} = lib::auth::getCustList();
				next;
			}

		}




		#===== Datasets available to all  users =================

		#----- hosts --------------------------------------------
		if ($ACTION_GET[$i] eq 'hosts') {
			if ($SESSION->param( 'cust_code' )) {
				my $hosts_json; 
				my $datafile = $DATAPATH . '/hostdata/' . $SESSION->param( 'cust_code' ) . '-hostdata.json';
				if (open( DATAFILE, "<$datafile" )) {
					while (<DATAFILE>) {
						chomp;
						$hosts_json .= $_; 
					}
					close( DATAFILE );
					my $hosts = from_json( $hosts_json );
					$RESPONSE{hPortal}{hosts} = $hosts;
				} else {
					appendError( "main::action_get[hosts]  Unable to open file [$datafile] for reading: $!\n" );
				}
			}
			next;
		}




		#----- notifications ------------------------------------
		if ($ACTION_GET[$i] eq 'notifications') {
			if ($SESSION->param( 'cust_code' )) {
				$RESPONSE{hPortal}{notifications} = lib::notifications::readEvents( $SESSION->param( 'cust_code' ) );
			}
			next;
		}




		#----- profile ---------------------------------------------
		if ($ACTION_GET[$i] eq 'profile') {
			my $profile;
			
			# The profile values are kept on the session. Profile is updated on action_set. 
			$profile->{username}  = $SESSION->param('username')    if $SESSION->param('username');
			$profile->{group}     = $SESSION->param('group')       if $SESSION->param('group');
			$profile->{cust_code} = $SESSION->param('cust_code')   if $SESSION->param('cust_code');
			$profile->{cust_name} = $SESSION->param('cust_name')   if $SESSION->param('cust_name');

			$RESPONSE{hPortal}{profile} = $profile;
			next;
		}




	} #for	
} #if 
#----- END "GET" Processor Engine -------------------------------------------------


print to_json( \%RESPONSE );

exit (0);
