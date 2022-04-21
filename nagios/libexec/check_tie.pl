#!/usr/bin/perl

###############################################################################################
#
# Name:		check_remote_url.pl
# Purpose:	Queries the given URL and parses it to test if the given components
#		of TIE are running or not
#
# $Id: check_tie.pl,v 1.1 2008/03/26 22:45:21 jkruse Exp $
# $Date: 2008/03/26 22:45:21 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use URI;
use LWP::UserAgent;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd; # This will be built later
my $optstr = 'I:H:C:S:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly
my $usage = '-I <ip address> -H <hostname> -S <service description> -C <customer code> -t <optional timeout>';

my ($output,$status_code);

# Function-specific variables
my $port;
my $url;
my %components;
my $hostname;

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
queryURL();

sub queryURL {
	my $ua = LWP::UserAgent->new;
	my $req;
	# In case the host is very sensitive about the HTTP headers it gets, if the port is 80,
	# just create a normal HTTP request without specifying the port number.
	if ($port == 80) {
		$req = HTTP::Request->new(GET => 'http://'.$args{I}.$url);
	} else {
		$req = HTTP::Request->new(GET => 'http://'.$args{I}.':'.$port.$url);
	}
	$ua->timeout($args{t}); # Set the timeout
	$ua->cookie_jar({}); # Turn on cookies and give it an in-memory temp cookie jar
	# Some application servers need the hostname sent back to them in the header,
	if (defined($hostname)) {
		$req->header(hostname => $hostname);
	}
	my $response = $ua->request($req);
	if (!$response->is_success) {
		# Request failed.  Could be for a whole garden variety of reasons (404, conection refused, etc. etc. etc.)
		$output = sprintf('%s',$response->status_line);
		$status_code = 3;
	} else {
		# The HTTP server gave us a valid response: Now parse to see if the components are
		# actually running or not.  The output should only be one line
		my @tokens = split(/\s+/,${$response->content_ref});
		foreach my $pair (@tokens) {
			if ($pair =~ /(\w+)=(\w+)/) {
				# Status codes on components: (used internally to this script)
				# 1: Running
				# 0: Not found (possibly a typo in the config file?)
				# -1: Not running
				if (exists($components{$1})) {
					if ($2 eq 'true') {
						$components{$1} = 1;
					} elsif ($2 eq 'false') {
						$components{$1} = -1;
					}
				}
			}
		}
		while(my ($component,$status) = each(%components)) {
			if ($status == -1) {
				$output.= sprintf('%s:Stopped ',$component);
			} elsif ($status == 0) {
				$output.= sprintf('%s:Not Found ',$component);
			}
		}
		# If output has been set, that means one or more components aren't running
		# (or not found) and the status code should be critical.  If not, then all
		# components are running.
		if ($output) {
			$status_code = 2;
		} else {
			$output = 'All Components Running';
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
				$port = $1;
				$arg_count++;
				next;
			}
			if (/^url:(.*)/) {
				$url = $1;
				$arg_count++;
				next;
			}
			if (/^component:(.*)/) {
				$components{$1} = 0;
				next;
			}
			# Hostname is optional (some app servers can't cope without this)
			if (/^hostname:(.*)$/) {
				$hostname = $1;
				next;
			}
				
		}
		close(FILE);
		if ($arg_count != 2 || scalar(keys(%components)) < 1) {
			print 'Required Arguments:port,url, and at least one TIE component (import_processor, etc.)';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
