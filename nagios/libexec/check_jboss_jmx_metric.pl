#!/usr/bin/perl

###############################################################################################
#
# Purpose:	Scrapes the JBOSS JMX MBean Inspector URL for the given metric's value
#		This script makes a lot of assumptions on how this page should look,
#		and may not work across all JMX metrics.  Buyer Beware!
#
# $Id: check_jboss_jmx_metric.pl,v 1.2 2008/04/10 23:54:26 jkruse Exp $
# $Date: 2008/04/10 23:54:26 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use URI;
use Getopt::Std;
use LWP::UserAgent;
use HTML::TableContentParser;

# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd; # This will be built later
my $optstr = 'I:H:C:S:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <optional timeout> -S "Service Description"',

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
		$output = sprintf('UNKNOWN: %s',$response->status_line);
		$status_code = 3;
	} else {
		# The request *may* have worked, need to extract the results
		# JMX output comes out as a craptastic table that requires an act of deity to parse
		# with regexs.  Thankfully, a deity known as CPAN has delivered us from evil with
		# the most excellent HTML::TableContentParser module
		my $p = HTML::TableContentParser->new();
		my $tables = $p->parse(${$response->content_ref}); # $tables is an array ref of all of the tables found
		my $count;
		foreach my $t (@$tables) {
			if (!defined($count)) {
				for my $r (@{$t->{rows}}) {
					if (defined($r->{cells})) {
						if (${$r->{cells}}[0]->{data} eq $config{metric}) {
							$count = ${$r->{cells}}[3]->{data};
							last;
						}
					}
				}
			} else {
				last;
			}
		}
		
		if ($count !~ /(\d+)/) {
			$output = sprintf('Unable to parse URL: %s (Port %d)',$config{url},$config{port});
			$status_code = 3;
		} else {
			$output = sprintf('%d|%d',$1,$1);
			if (exists($config{threshold})) {
				if ($count >= $config{threshold}) {
					$status_code = 2;
				} else {
					$status_code = 0;
				}
			} else {
				$status_code = 0;
			}
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
			}
			if (/^url:(.*)/) {
				$config{url} = $1;
				$arg_count++;
				next;
			}
			if (/^metric:(.*)/) {
				$config{metric} = $1;
				$arg_count++;
				next;
			}
			# threshold is optional: if set, is the number of threads found
			# to trigger an alert
			if (/^threshold:(\d+)$/) {
				$config{threshold} = $1;
				next;
			}
			# Hostname is optional (some app servers can't cope without this)
			if (/^hostname:(.*)$/) {
				$config{hostname} = $1;
				next;
			}
				
		}
		close(FILE);
		if ($arg_count != 3) {
			print 'port,url, and metric are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
