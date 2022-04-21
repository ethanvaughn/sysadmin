#!/usr/bin/perl

###################################################################################
#
# Name:		aliases_client.pl
# Purpose:	Retrieves latest on-call assignments from oncall DB and updates
#		the file $aliases with the latest aliases.  These are used
#		primarily by Nagios for alerting, but could be used in other
#		applications as well.
#
# $Id: aliases_client.pl,v 1.5 2008/01/04 04:42:46 jkruse Exp $
# $Date: 2008/01/04 04:42:46 $
#
###################################################################################

use strict;
use URI;
use Getopt::Std;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

# Notes on Nagios Integration
# Nagios integration can be turned on/off via the $nagios_integration_enabled variable
# 1 - Enables integration
# 2 - Disables integration
# The only variable that should require changing for Nagios integration is the IP address of the Nagios server.
# Each monitoring server monitors another monitoring server (WDC <> SDC, for example) and should submit checks not
# to itself, but to the monitoring server that monitors it

# Globals
my %args;
my $new_oncall_aliases;
my $logger = '/usr/bin/logger';
my $aliases = '/etc/aliases_oncall';
my $newaliases = '/usr/bin/newaliases';
my $timeout = 15;

# Nagios Integration Globals
my $nagios_integration_enabled = 1;		# 1 = Integration Enabled, 0 = Integration Disabled
my $nagios_url = '/pcgi/submitcheck.cgi';	# URL for submitting check
my $nagios_svc = 'OnCall DB Email Aliases';	# Nagios service name


getArgs();
queryServer();
compareAliases();

sub compareAliases {
	my $current_aliases;
	my $open = open(FH,$aliases);
	if (!$open) {
		logger("compareAliases() ERROR: $!",2);
		exit -1;
	}
	while(<FH>) {
		$current_aliases.= $_;
	}
	close(FH);
	# Now compare the two.  Keep in mind $new_oncall_aliases
	# is a scalar ref, not an actual scalar
	if ($$new_oncall_aliases eq $current_aliases) {
		logger('Aliases are up to date',0);
	} else {
		updateAliases();
	}
}

sub updateNagios {
	my ($output,$status_code) = @_;
	my $cmd = sprintf('PROCESS_SERVICE_CHECK_RESULT$%s$%s$%d$%s',$args{H},$nagios_svc,$status_code,$output);
	if ($args{M} eq 'test') {
		# In test mode it's helpful to see what the command being sent to Nagios
		# looks like, prints to STDOUT
		print $cmd,"\n";
	}
	my $ua = LWP::UserAgent->new();
	$ua->timeout($timeout);
	my $req = POST 'http://'.$args{N}.$nagios_url,[ cmd => $cmd ];
	my $response = $ua->request($req);
	if (!$response->is_success) {
		# The only real action we can take if we were unable to post a service check result
		# to Nagios is to log it.  Note that we omit the status code here -- we're already trying
		# to update Nagios; if this failed, and we pass a status code to logger, it would
		# cause an infinite loop.  Just log the error.
		logger('Error Posting Service Check: '.$response->status_line);
	}

}

sub updateAliases {
	if ($args{M} eq 'test') {
		print 'OnCall aliases would be updated, but running in test mode',"\n",$$new_oncall_aliases;
	} elsif ($args{M} eq 'prod') {
		my $open = open(FH,">$aliases");
		if ($open) {
			print FH $$new_oncall_aliases;
			close(FH);
			system($newaliases);
			logger('OnCall Aliases Updated',0);
		} else {
			logger("updateAliases() ERROR: $!",2);
		}
	}
}

sub queryServer {
	my $ua = LWP::UserAgent->new();
	my $req = HTTP::Request->new(GET => 'http://'.$args{I}.$args{U});
	$ua->timeout($timeout);
	my $response = $ua->request($req);
	if ($response->is_success) {
		$new_oncall_aliases = $response->content_ref;
		# Now here is the tough part: we need to validate each line of $new_oncall_aliases
		my @lines = split(/\r\n|\n/,$$new_oncall_aliases);
		my $has_invalid_aliases = 0;
		foreach my $line (@lines) {
			chomp($line);
			if ($line =~ /^#/) {
				# Comments are allowed
				next;
			} elsif ($line =~ /^[0-9A-Z_-]+:(?:\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b)/i) {
				# The above regex attempts to validate the following format: (minus the pound sign, of course)
				#something-something-something:(one or more email addresses)
				# For example:
				#sysadmin-oncall-email:bob@asdf.com
				# This regex doesn't validate multiple entry cases though, such as the following:
				#sysadmin-oncall-email:bob@asdf.com,foo@bar.com
				# If you the clever reader of this script can think of a regex to do that, try it!
				next;
			} else {
				$has_invalid_aliases = 1;
				logger('Invalid alias found:'.$line);
			}
		}
		if ($has_invalid_aliases) {
			logger('One or more invalid aliases found, aborting and leaving '.$aliases.' alone',2);
			exit -1;
		}
	} else {
		logger('(aborting) ERROR: '.$response->status_line,2);
		exit -1;
	}
}

sub logger {
	my ($message,$status_code) = @_;
	if ($message) {
		my $cmd = sprintf('%s "%s:%s"',$logger,$0,$message);
		system($cmd);
		# If this is in test mode, print the error to STDOUT
		# in addition to logging to syslog
		if ($args{M} eq 'test') {
			print $message,"\n";
		}
	}
	if (defined($status_code) && $nagios_integration_enabled) {
		updateNagios($message,$status_code);
	}
}

sub getArgs {
	getopts('I:U:M:H:N:',\%args);
	my $count = 0;
	if (exists($args{I}) && exists($args{U})) {
		$count++;
	}
	if (exists($args{M}) && ($args{M} eq 'test' || $args{M} eq 'prod')) {
		$count++;
	}
	if (exists($args{H})) {
		$count++;
	}
	if ($nagios_integration_enabled) {
		if (exists($args{N})) {
			$count++;
		}
	} else {
		# Increment the counter such that this will return normally
		# since Nagios integration is disabled
		$count++;
	}
	if ($count != 4) {
		usage();
	}
}

sub usage {
	print 'Usage: ',$0,' -I <IP address> -U <url> -M <test|prod> -H <nagios hostname> -N <nagios IP (optional)>',"\n";
	print "\t",'-N only takes effect if the $nagios_integration_enabled global is set to 1 inside the script',"\n";
	exit -1;
}
