#!/usr/bin/perl

###############################################################################################
#
# Name:		check_remote_url.pl
# Purpose:	Queries the given URL.  A centralized monitoring replacement for the Nagios
#		check_http plugin.  In addition to querying a URL, can also test if the
#		HTTP response contains a given string or not set via match: in the config file
#
# $Id: check_remote_url.pl,v 1.5 2008/07/11 19:17:54 jkruse Exp $
# $Date: 2008/07/11 19:17:54 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use URI;
use ArgParse;
use LWP::UserAgent;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $optstr = 'I:H:C:S:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',
my $suffix; # Determined on the fly

my ($output,$status_code);

# Function-specific variables
my %config; # Config directives go here

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
queryURL();

sub queryURL {
	my $ua = LWP::UserAgent->new;
	my $req;
	# In case the host is very sensitive about the HTTP headers it gets, if the port is 80,
	# just create a normal HTTP request without specifying the port number.
	if ($config{port} == 80) {
		$req = HTTP::Request->new(GET => 'http://'.$args{I}.$config{url});
	} else {
		$req = HTTP::Request->new(GET => 'http://'.$args{I}.':'.$config{port}.$config{url});
	}
	$ua->timeout($args{t}); # Set the timeout
	$ua->cookie_jar({}); # Turn on cookies and give it an in-memory temp cookie jar
	# Some application servers need the hostname sent back to them in the header,
	if (exists($config{hostname})) {
		$req->header(hostname => $config{hostname});
	}
	my $response = $ua->request($req);
	if (!$response->is_success) {
		# Request failed.  Could be for a whole garden variety of reasons (404, conection refused, etc. etc. etc.)
		$output = $response->status_line;
		$status_code = 3;
	} else {
		# Check if hide_url is set to true.  If it is, change $config{url} to just be 'URL'
		if (exists($config{hide_url})) {
			$config{url} = 'URL';
		}
		# The request *may* have worked, depending on if we're testing string matches or not
		if (exists($config{match_string})) {
			if (${$response->content_ref} =~ /$config{match_string}/) {
				$output = sprintf('%s contains "%s" in response (Port %d)',$config{url},$config{match_string},$config{port});
				$status_code = 0;
			} else {
				$output = sprintf('"%s" missing in %s (Port %d)',$config{match_string},$config{url},$config{port});
				$status_code = 2;
			}
		} else {
			# We are just testing to make sure we get a HTTP 200 response
			$output = sprintf('%s Response OK - %d Bytes (Port %d)',$config{url},length(${$response->content_ref}),$config{port});
			$status_code = 0;
		}
	}
	print $output;
	exit $status_code;
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
			} elsif (/^url:(.*)/) {
				$config{url} = $1;
				$arg_count++;
				next;
			} elsif (/(.*):(.*)/) {
				# Get all optional directives
				$config{$1} = $2;
			}
		}
		close(FILE);
		if ($arg_count != 2) {
			print 'port and url are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
