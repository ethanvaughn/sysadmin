#!/usr/bin/perl

###############################################################################################
#
# Name:		check_isd_settlement.pl
# Purpose:	Logs into the ISD Web UI and parses the web pages
#		to determine if settlement has completed for the
#		current date
#
# $Id: check_isd_settlement.pl,v 1.3 2008/01/21 17:01:03 jkruse Exp $
# $Date: 2008/01/21 17:01:03 $
#
###############################################################################################

use strict;
use URI;
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd; # This will be built later
my @args = qw(I H C t S); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

my ($output,$status_code);

# Function-specific variables
my %config; # Config directives go here

# Main Body
getArgs();
readThresholds();
queryURL();

sub queryURL {
	# A few notes on this function...
	#
	# As you'll notice, there are short-circuits everywhere.  This function
	# is divided into steps.  Each step depends on successful completion of the
	# previous step.
	#
	# Also, there's a lot of code here that is dependent on very specific behaviour from
	# ISD's software that may change version to version; it's unknown at the time
	# of this writing if future versions of ISD will require extracting the form
	# action, the output will change for login success/failure, etc. etc.

	# Step 1: Instantiate core objects and configure them
	my $ua = LWP::UserAgent->new;
	$ua->timeout($args{t}); # Set the timeout
	$ua->cookie_jar({}); # Turn on cookies and give it an in-memory temp cookie jar
	push(@{$ua->requests_redirectable},'POST'); # Tell this UA to follow POST redirects (disabled by default)
	my $response; # We will reuse this variable for the HTTP response on each query

	# Step 2: Query the login URL: this assigns us a session ID, etc.
	my $base_request = HTTP::Request->new(GET => 'http://'.$args{I}.':'.$config{port}.$config{base_url});
	$response = $ua->request($base_request);
	if (!$response->is_success) {
		# Request failed.  Could be for a whole garden variety of reasons (404, conection refused, etc. etc. etc.)
		printf('Base ISD Login URL Failed: %s',$response->status_line);
		exit 3;
	}

	# Step 3: Extract the form action
	my $form_action;
	if (${$response->content_ref} !~ /action="(.*)"\s/) {
		printf('Unable to find form action tags in %s (Port %d)',$config{base_url},$config{port});
		exit 3;
	}

	# Step 4: Login to the ISD Switch
	$form_action = $1;
	my $post_url = sprintf('http://%s:%d%s',$args{I},$config{port},$form_action);
	my $post_request = POST $post_url,[j_username => $config{username},j_password => $config{password},j_uri => '',login => 'Login'];
	$response = $ua->request($post_request);
	if (!$response->is_success) {
		printf('Failed to login: ',$response->status_line);
		exit 3;
	} elsif (${$response->content_ref} !~ /logged in successfully/i) {
		# In addition to detecting whether or not the page came back OK, parse the
		# output and check if the username/password was accepted or not.  We have to
		# parse the content of the page to determine this; the HTTP status code
		# is a 200 whether we authenticate OK or not.
		printf('Failed to login: Incorrect Username/Password');
		exit 3;
	}

	# Step 5: Query the settlement URL
	my $settlement_request = HTTP::Request->new(GET => 'http://'.$args{I}.':'.$config{port}.$config{settlement_url});
	$response = $ua->request($settlement_request);
	if (!$response->is_success) {
		printf('Failed to query Settlement URL: ',$response->status_line);
		exit 3;

	}

	# Step 6: Parse the output
	if (${$response->content_ref} !~ /<p>The last settlement job completed at\s+(\w.*)</) {
		print 'Unable to determine if settlement completed';
		exit 3;
	}
	my $settlement_response = $1;
	if ($settlement_response !~ /^(\w+).*(\d{2}:\d{2}:\d{2})/) {
		print 'Unreadable response in settlement completion time';
		exit 3;
	}

	# Step 7: Check if the day settlement completed is TODAY
	my $settlement_day_completed = $1;
	my $settlement_time_completed = $2;
	my @days = qw(Sun Mon Tue Wed Thu Fri Sat);
	my @localtime = localtime(); # $localtime[6] = day of week (0-6, 0 = Sunday, 1 = Monday ...)
	if ($days[$localtime[6]] eq $settlement_day_completed) {
		printf('Settlement has completed at %s',$settlement_time_completed);
		exit 0;
	} else {
		printf('Settlement not completed for current date (Last Completed: %s)',$settlement_response);
		exit 2;
	}
}

sub readThresholds {
	# This function is for reading the config in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/; # cheap and easy way to allow for comments
			if (/^port:(\d+)$/) {
				$config{port} = $1;
				$arg_count++;
				next;
			}
			if (/^base_url:(.*)/) {
				$config{base_url} = $1;
				$arg_count++;
				next;
			}
			if (/^settlement_url:(.*)/) {
				$config{settlement_url} = $1;
				$arg_count++;
				next;
			}
			if (/^username:(.*)$/) {
				$config{username} = $1;
				$arg_count++;
				next;
			}
			if (/^password:(.*)$/) {
				$config{password} = $1;
				$arg_count++;
				next;
			}
				
		}
		close(FILE);
		if ($arg_count != 5) {
			print 'UNKNOWN: port,base_url,settlement_url,username,password are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}

sub getArgs {
	# This is the basic code here.  It doesn't do any validation
	# other than a parameter was supplied to each of the arguments.
	# Customize as appropriate to add additional validators
	# If, for example, command-line arguments affect the parameters passed to the remote
	# command, append them to $cmd here (assuming they validate, of course)
	my $validated_args = 0;
	my $optstr = join(':',@args);
	$optstr.= ':'; # join misses the very last colon
	getopts($optstr,\%args);
	foreach my $arg (@args) {
		if(exists($args{$arg})) {
			$validated_args++;
		}
	}
	if ($validated_args == scalar(@args)) {
		# All of the arguments have been validated
		$suffix = $args{S};
		return;
	} else {
		usage();
	}
}

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
		"\n";
	exit 3;
}
