#!/usr/bin/perl

###############################################################################################
#
# Purpose:	Scrapes the JBOSS web console URL for memory usage stats
#
# $Id: check_jboss_jvm_mem_auth.pl,v 1.1 2009/01/30 22:46:08 evaughn Exp $
# $Date: 2009/01/30 22:46:08 $
#
###############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use URI;
use Getopt::Std;
use LWP::UserAgent;

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

#----- setScale --------------------------------------------------------------------------
# Internal helper function to normalize reported memory sized to Mb. 
sub setScale {
	my $val = shift;
	my $mag = shift; # magnitude (K, M, G)
	my $result = $val;
	
	if ($mag eq "K") {
		$result = $val / 1024;
	}
	if ($mag eq "G") {
		$result = $val * 1024;
	}

	return $result;
}



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
	
	$ua->credentials(
		"$args{I}:$config{port}",
		"$config{realm}",
		"$config{username}",
		"$config{password}"
	);
		
	my $response = $ua->request($req);
	if (!$response->is_success) {
		# Request failed.  Could be for a whole garden variety of reasons (404, conection refused, etc. etc. etc.)
		$output = sprintf('UNKNOWN: %s',$response->status_line);
		$status_code = 3;
	} else {
		# The request *may* have worked, need to extract the results
		my $free;
		my $free_c;
		my $max;
		my $max_c;
		my $total;
		my $total_c;
		my $matched_values = 0;		# Counter of values we've found so far
		my $target_match_count = 3;	# Number of values we want
		foreach my $line (split(/\n/,${$response->content_ref})) {
			# If we've already found $target_match_count values, stop looking
			if ($matched_values == $target_match_count) {
				last;
			}
			if ($line =~ /Free Memory:\D+(\d+ \w)/) {
				($free,$free_c) = split( / /, $1 );
				$free = setScale( $free, $free_c );
				$matched_values++;
				next;
			}
			if ($line =~ /Max Memory:\D+(\d+ \w)/) {
				($max,$max_c) = split( / /, $1 );
				$max = setScale( $max, $max_c );
				$matched_values++;
				next;
			}
			if ($line =~ /Total Memory:\D+(\d+ \w)/) {
				($total,$total_c) = split( / /, $1 );
				$total = setScale( $total, $total_c );
				$matched_values++;
				next;
			}
		}
		if ($matched_values != $target_match_count) {
			$output = sprintf('Unable to parse URL: %s (Port %d)',$config{url},$config{port});
			$status_code = 3;
		} else {
			# These values are in MB, multiply $1,$2,$3 * 1048576 to get bytes
			my $MULT = 1048576;
			# Now calculate percentages
			my $used = $total-$free;
			my $percent_used = $used/$max*100;
			$output = sprintf
						(
						'Used: %0.f MB (%0.f%) Total: %0.f MB|total:%0.f free:%0.f max:%0.f',
						$used,
						$percent_used,
						$max,
						$total * $MULT,
						$free * $MULT,
						$max * $MULT
						);
			if ($percent_used > $config{percent_used}) {
				$status_code = 2;
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
			if (/^percent_used:(\d+)/) {
				$config{percent_used} = $1;
				$arg_count++;
				next;
			}
			if (/^username:(.*)/) {
				$config{username} = $1;
				$arg_count++;
				next;
			}
			if (/^password:(.*)/) {
				$config{password} = $1;
				$arg_count++;
				next;
			}
			if (/^realm:(.*)/) {
				$config{realm} = $1;
				$arg_count++;
				next;
			}
			# Hostname is optional (some app servers can't cope without this)
			if (/^hostname:(.*)$/) {
				$config{hostname} = $1;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 6) {
			print 'port, url, username, password, realm, and percent_used are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
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
