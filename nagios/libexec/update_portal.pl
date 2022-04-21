#!/usr/bin/perl

#####################################################################################################
#
# Purpose:	Updates Tomax Portal /w status
#		Also, on service recoveries, if service is in
#		scheduled downtime from the ACK tool, removes the downtime
#		This is only compatible with Nagios 2.x.  In 3.x, there is no downtime
# 		file (these details are stored in status.dat)
#
# $Id: update_portal.pl,v 1.3 2008/09/03 23:26:08 jkruse Exp $
# $Date: 2008/09/03 23:26:08 $
#
#####################################################################################################

use strict;
use URI;
use Getopt::Long;
use Fcntl ':flock';
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

# Configuration Directives
my $portal_ip = 			'10.24.74.13'; # IP of Portal
my $portal_url = 			'/portal/bin/notificationCGI.pl'; # URL to POST portal update commands to
my $downtime_file =			'/u01/app/nagios/var/downtime.dat'; # Location of downtime file (Nagios 2.x)
my $downtime_string = 			'ACK_MAINT'; # String to look for in downtime entry (services only)
my $fifo =				'/u01/app/nagios/var/rw/nagios.cmd'; # Location of Nagios FIFO

# Command-line args
my $mode;				# H or S (Host/Service)
my $customer;				# Customer Abbreviation (PC,AND, etc.)
my $stateid;				# State ID (0,1,2,3)
my $statetype;				# HARD or SOFT
my $servicedesc;			# Service Description (CPU Usage, Load Average..)
my $output;				# Plugin Output (user-viewable output from host/service check)
my $hostname;				# Name of the host (i.e tmxdb01prod)
my $hostalias;				# Description of the host (i.e, SDS APP Server)
my $host_downtime;			# 0 if not in downtime, > 0 otherwise
my $service_downtime;			# 0 if not in downtime, > 0 otherwise

# Main Body

getArgs();
checkDowntime();
buildAndSendMessage();

# Functions

sub buildAndSendMessage {
	my $message;
	if ($host_downtime || $service_downtime) {
		$message = '(Maintenance Window) ';
	}
	if ($mode eq 'H') {
		if ($stateid == 0) {
			$message.= 'UP: ';
		} elsif ($stateid == 1) {
			$message.= 'DOWN: ';
		} elsif ($stateid == 2) {
			$message.= 'UNREACHABLE: ';
		} else {
			die 'buildAndSendMessage(): invalid host state ID';
		}
		$message.= sprintf('%s (%s): %s',$hostalias,$hostname,$output);
	} elsif ($mode eq 'S') {
		if ($stateid == 0) {
			$message.= 'OK: ';
		} elsif ($stateid == 1) {
			$message.= 'WARNING: ';
		} elsif ($stateid == 2) {
			$message.= 'CRITICAL: ';
		} elsif ($stateid == 3) {
			$message.= 'UNKNOWN: ';
		} else {
			die 'buildAndSendMessage(): invalid service state ID';
		}
		$message.= sprintf('%s/%s (%s): %s',$hostalias,$servicedesc,$hostname,$output);
	}
	# Now message is built, build command string that is sent to portal
	my $portal_string = sprintf('%s$%d$%s',$customer,$stateid,$message);
	# Build URL
	my $url = sprintf('http://%s%s',$portal_ip,$portal_url);
	# Send to Portal
	my $ua = LWP::UserAgent->new;
	$ua->timeout(5);
	my $post_request = POST($url,[arg => $portal_string]);
	#printf('Posting POST: %s%s',$portal_string,"\n");
	my $response = $ua->request($post_request);
	if (!$response->is_success) {
		my $error = sprintf('Unable to update Portal: %s',$response->status_line);
		die $error;
	}
}

sub checkDowntime {
	# This only applies if we are in service mode
	if ($mode eq 'H') {
		return;
	} else {
		if ($stateid == 0) {
			# This is a recovery: is the service in scheduled downtime?
			if ($service_downtime) {
				# If the scheduled downtime is a result of the ACK tool,
				# this downtime entry needs to be removed.  But before going any further,
				# change $service_downtime to 0.  Functions later in execution will look
				# at this variable to determine how the message looks that is sent to
				# the portal.
				$service_downtime = 0;
				removeServiceDowntime();
			}
		}
	}
}

sub removeServiceDowntime {
	# This function does two things:
	# 1) Reads the downtime file to find the downtime entry for this service
	# 2) If this service is in downtime as a result of the ACK tool, tells Nagios to
	#	remove this downtime entry (submits a command to the FIFO with the
	#	downtime ID to remove)
	my $fh; # File handle to be used for reading the file
	my $res = open($fh,$downtime_file);
	if (!$res) {
		# Couldn't open the file, which is very strange
		# to say the least.  Best to just give up and die
		die 'Unable to open downtime file';
	} else {
		my $id;
		while(<$fh>) {
			if (/^servicedowntime {/) {
				$id = readServiceDowntimeEntry($fh);
				if ($id) {
					last;
				}
			}
		}
		if ($id) {
			# There was a downtime entry that matched.  Build the Nagios command,
			# and submit it to the FIFO.  Nagios will then remove the downtime entry
		}
		my $nagios_cmd = sprintf('[%lu] DEL_SVC_DOWNTIME;%d%s',time(),$id,"\n");
		#printf('Would submit: %s',$nagios_cmd);
		writeToFIFO($nagios_cmd);
	}
}

sub readServiceDowntimeEntry {
	my $fh = shift;		# Filehandle to read
	my $id;			# Downtime ID associated with this service
	my $downtime_matches;	# Boolean true if comment matches ACK Tool
	my $this_host;		# Boolean true if downtime entry in file matches $hostname
	my $this_service;	# Boolean true if downtime entry in file matches $servicedesc
	while(<$fh>) {
		if (/host_name=$hostname/) {
			$this_host = 1;
		}
		if (/service_description=$servicedesc/) {
			$this_service = 1;
		}
		if (/downtime_id=(\d+)/) {
			$id = $1;
		}
		if (/comment=$downtime_string/) {
			$downtime_matches = 1;
		}
		if (/}/) {
			last;
		}
	}
	if ($this_host && $this_service && $downtime_matches) {
		return $id;
	} else {
		return undef;
	}
}

sub getArgs {
	GetOptions(
		'mode=s' => \$mode, # Mode: H or S (Host or Service context)
		'cust=s' => \$customer, # Customer abbreviation
		'stateid=i' => \$stateid, # State ID (0-3)
		'statetype=s' => \$statetype, # State type (HARD|SOFT)
		'service=s' => \$servicedesc, # Service Name
		'output=s' => \$output, # Service output
		'host=s' => \$hostname, # Host name (v19u23, rat12, etc.)
		'hostalias=s' => \$hostalias, # Host description (i.e, ATG DB Server)
		'hostdowntime=i' => \$host_downtime, # 0 if not in downtime, > 0 otherwise
		'servicedowntime=i' => \$service_downtime # 0 if not in downtime, > 0 otherwise
		);
	# Now validate all of the arguments

	# If this is not a hard state, do nothing and exit
	if ($statetype ne 'HARD') {
		# Used during debugging
		#printf('Exited on soft state%s',"\n");
		#usage();
		exit 0;
	}

	# For all modes of operation, the following is required
	# $customer
	# $hostname
	# $hostalias
	# $output
	# $host_downtime
	# $stateid
	if (defined($customer) && defined($hostname) && defined($hostalias) && defined($output) && defined($host_downtime) && defined($stateid)) {
		# The number of arguments examined here depends on mode.  In Host mode (H)
		# there is no $service_downtime
		if ($mode eq 'H') {
			# There's nothing left to validate
		} elsif ($mode eq 'S') {
			# In service mode -servicedowntime and -service are required arguments
			if (!defined($service_downtime)) {
				usage();
			}
			if (!defined($servicedesc)) {
				usage();
			}
		} else {
			usage();
		}
	} else {
		#printf('missing customer,hotname,hostalias,output,hostdowntime, or stateid%s',"\n");
		usage();
	}
	# If we get here, everything has been validated and we are OK to move on
	return;
}

sub writeToFIFO {
	# This command expects a nicely formatted string to just write to the Nagios FIFO.  It does no
	# formatting, etc.  Just lock the FIFO, write your junk, and return
	my $cmd = shift;
	# Note the open mode (write, in this case) is specified by sprintf, not in open() as might be
	# traditionally done.  This is functionally the same as the following:
	# open(FH,">$fifo"), just without the double-quotes that are a perl no-no
	if (-p $fifo) {
		my $nagios = sprintf('>%s',$fifo);
		eval {
			local $SIG{ALRM} = sub { die 'Connection timed out' };
			alarm(5);
			open(FH,$nagios) || die 'Unable to open FIFO for writing';
			# FIFOs on Linux can't hold a lot of data.  To keep from overloading the FIFO, we do
			# an exlcusive lock so that the other processes writing to this FIFO will have to queue up
			# so as to prevent buffer overflows.  (Which are very easy to cause with FIFOs!)
			flock(FH,LOCK_EX) || die 'Unable to lock FIFO';
			syswrite(FH,$cmd);
			flock(FH,LOCK_UN);
			close(FH);
			# Diagnostics during testing
			#print $cmd;
			alarm(0);
		};
	} else {
		die 'FIFO does not exist or is not a valid named pipe (FIFO)';
	}
}

sub usage {
	print 'Usage: ',$0,"\n";
	print "\t",'-mode <H|S>',"\n";
	print "\t",'-cust <customer abbrev>'."\n";
	print "\t",'-stateid <0-3>'."\n";
	print "\t",'-statetype <HARD|SOFT>'."\n";
	print "\t",'-host <hostname>'."\n";
	print "\t",'-hostalias <host alias>'."\n";
	print "\t",'-hostdowntime <0-2>'."\n";
	print "\t",'-service <service name>'."\n";
	print "\t",'-servicedowntime <0-2>'."\n";
	print "\t",'-output <host/service check output>'."\n";
	print "\n";
	exit -1; 
}
