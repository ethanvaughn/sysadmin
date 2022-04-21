#!/usr/bin/perl

#####
#
# update_portal.pl: Updates TMX Portal /w data from Nagios
#
# Author:	Jake Kruse
# Version:	1.0
# Last Updated:	12/30/2006
# Revision History
#		v1.0 - 12/30/2006 - Initial Release
#
#####

use strict;

use Socket;
use Getopt::Long;

# Incoming arguments
my ($mode,$customer,$stateid,$statetype,$service,$output,$hostname,$hostalias);

# Globals
my $portal_ip = '10.24.74.20'; 
my $statusfile = '/u01/app/nagios/var/status.dat';
#my $statusfile = 'example_status.dat';
my $portal_message;
my $portal_severity;
my %service;
my %host;
my $fh;

### Main

getArgs();
openFile();
checkHost();
checkService();
buildMessage();
updatePortal();

### End Main

### Functions

# openStatusFile: Just opens the file (or errors out the EV)
sub openFile {
	open($fh,$statusfile) || die $!;
}

# checkService: read in service record (if applicable) into %service hash
sub checkService {
	if ($mode eq 'H') {
		# Only looking at status of host -- don't bother
		return;
	} else {
		# Read in the service record
		my $rec;
		while(<$fh>) {
			chomp;
			if(/^service {/) {
				$rec = readServiceRec();
				if (defined($rec)) {
					# Found it!
					# Set properties into %service
					# Debug
					#print "found $service on $hostname\n";
					if ($rec->{notifications_enabled} == 1) {
						$service{notifications} = 1;
					}
					if ($rec->{is_flapping} == 1) {
						$service{flapping} = 1;
					}
					if ($rec->{scheduled_downtime_depth} > 0) {
						$service{maint} = 1;
					}
					# If this service record has been located, stop
					# processing the file
					last;
				}
			}
		}
	}
	# Since checkService is executed after checkHost, it is safe to close the filehandle here
	close($fh); # Don't bother checking for errors!
}

# checkHost: read in a host record and store relevant info in %host
sub checkHost {
	# Read in the host record	
	my $rec;
	while(<$fh>) {
		chomp; # Remove newline from each line now (will need to do it for every line, anyway)
		if (/^host {/) {
			$rec = readHostRec();
			if (defined($rec)) {
				# Found it!
				# Set properties in %host
				# Debug
				#print "Found record for $hostname\n";
				if ($rec->{notifications_enabled} == 1) {
					$host{notifications} = 1;
				}
				if ($rec->{is_flapping} == 1) {
					$host{flapping} = 1;
				}
				if ($rec->{scheduled_downtime_depth} > 0) {
					$host{maint} = 1;
				}
				# In the case of being in host mode (mode = H)
				# this field is totally irrelevant
				# But, in the case of when executed in service mode (mode = S)
				# we do need to know the state of the host itself
				$host{status} = $rec->{current_state};
				# Since this host record has been found, stop processing
				last;
			}
		}
	}
	
	
}

# readHostRec: finds the host record in status file that matches $hostname
# prerequisite: expects that $fh has already been set to point at the start of a host record
sub readHostRec {
	my %rec;
	my $status == 0;
	while(<$fh>) {
		s/^\s+//; # remove all leading whitespace
		if (/}$/) {
			# End of Record (EOR)
			last;
		} elsif ($status == -1) {
			# Not this record: keep skipping until EOR is reached
			next;
		} elsif ($status == 1) {
			# This record matches, stuff all properties into %rec
			my @line = split(/=/);
			if (scalar(@line) == 2) {
				$rec{$line[0]} = $line[1];
			}
		} elsif (!$status) {
			# Might be this record
			if (/host_name=(\w+)/) {
				if ($hostname eq $1) {
					# Matched record
					$status = 1;
				} else {
					# This record isn't it
					$status = -1;
				}
			}
		}
	}
	if ($status == 1) {
		return \%rec;
	} else {
		return undef;
	}
}

# readServiceRec: finds the host record in status file that matches $hostname
# prerequisite: expects that $fh has already been set to point at the start of a service record
sub readServiceRec {
	my %rec; # Where to store this record
	my $status == 0; # Will be set to 1 when this record is for the right hostname, 2 when right host+service rec
	while(<$fh>) {
		s/^\s+//; # Remove all leading whitespace
		if (/}$/) {
			# End of record (EOR) - exit loop
			last;
		} elsif ($status == -1) {
			# Not this record: keep skipping until EOR is reached
			next;
		} elsif ($status == 2) {
			# This record matches, load the hash
			my @line = split(/=/);
			if (scalar(@line) == 2) {
				$rec{$line[0]} = $line[1];
			}
		} elsif (!$status) {
			# Might be this record -- check hostname
			if (/host_name=(\w+)/) {
				if ($hostname eq $1) {
					# Matched record
					$status = 1;
				} else {
					# This record isn't it
					$status = -1;
				}
			}
		} elsif ($status == 1) {
			# The service belongs to the right host,
			# but check to see if this is the right service
			if (/service_description=(.*)/) {
				if ($service eq $1) {
					# Matching record
					$status = 2;
				} else {
					# It's for the right host, but this is
					# for the wrong service.  Skip rest of record
					$status = -1;
				}
			}
		}
	}
	if ($status == 2) {
		return \%rec;
	} else {
		return undef;
	}
}

sub buildMessage {
	# For both host and service modes, if the host / service record could not be located,
	# (meaning that the specified host or host/service could not be found)
	# checking $host{notifications} or $service{notifications} will return a zero, and
	# this will exit as if notifications were turned off
	if ($mode eq 'H') {
		# Notifications enabled?
		# If notifications are disabled, there's no reason for this to update anything
		if ($host{notifications} == 0) {
			# Debug
			#print "$hostname has notifications disabled, exiting\n";
			exit 0;
		}
		# Flapping?
		if ($host{flapping} == 1) {
			# Debug
			#print "$hostname is flapping, exiting\n";
			exit 0;
		}
		if ($host{maint} == 1) {
			$portal_message = '(Maintenance Window) ';
		}
		$portal_message.= "$hostname ($hostalias) is ";
		if ($stateid == 0) {
			$portal_message.= 'UP: ';
		} elsif ($stateid == 1) {
			$portal_message.= 'DOWN: ';
		} elsif ($stateid == 2) {
			$portal_message.= 'UNREACHABLE (Network Outage): ';
		} else {
			# We got a weird, cracked out state id that doesn't make sense
			# for hosts, state id can only be 0,1,2 for up,down,unreachable
			die 'buildMessage: Invalid host state';
		}
	} elsif ($mode eq 'S') {
		# Notifications enabled?  If not, exit
		if ($service{notifications} == 0) {
			# Debug
			#print "$service is disabled on $hostname\n";
			exit 0;
		}
		# Is it flapping? If so, exit
		if ($service{flapping} == 1) {
			# Debug
			#print "$service is flapping on $hostname\n";
			exit 0;
		}
		# Is the host up?  If not, exit
		if ($host{status} != 0) {
			# Debug
			#print "$hostname is down, ignoring service status\n";
			exit 0;
		}
		# Is either the host or service in a maintenance window?
		if ($host{maint} == 1 || $service{maint} == 1) {
			$portal_message = '(Maintenance Window) ';
		}
		$portal_message.= "$hostname ($hostalias) $service is ";
		# Add the state type
		if ($stateid == 0) {
			$portal_message.= 'OK: ';
		} elsif ($stateid == 1) {
			$portal_message.= 'WARNING: ';
		} elsif ($stateid == 2) {
			$portal_message.= 'CRITICAL: ';
		} elsif ($stateid == 3) {
			$portal_message.= 'UNKNOWN: ';
		} else {
			# Valid service states are 0,1,2,3 for ok, warning, critical, and unknown
			# anything else indicates some cracked out error happened
			die 'buildMessage: invalid service state';
		}
	}
	# Set the severity in portal (currently, this corresponds to Nagios state types)
	$portal_severity = $stateid;
	# Add plugin output
	$portal_message.= $output;
	# Check state type (for both hosts and services)
	# If soft non-OK state, indicate some kind of retry
	if ($statetype eq 'SOFT' && $stateid > 0) {
		$portal_message.= ' (Will be retried)';
	}
	# Debugging
	#print $portal_message,"\n";
	#exit 0;
}

sub getArgs {
	GetOptions(
		'mode=s' => \$mode, # Mode: H or S (Host or Service context)
		'cust=s' => \$customer, # Customer abbreviation
		'stateid=i' => \$stateid, # State ID (0-3)
		'statetype=s' => \$statetype, # State type (HARD|SOFT)
		'service=s' => \$service, # Service Name
		'output=s' => \$output, # Service output
		'host=s' => \$hostname, # Host name (i.e, V19U23)
		'hostalias=s' => \$hostalias); # Host description (i.e, ATG DB Server)
	# Now validate the commands
	# For most variables just check that they are defined
	# To increase readability this if statement has been spread out across multiple lines
	if (
		($mode eq 'H' || $mode eq 'S') && 
		defined($customer) &&
		($stateid >= 0 || $stateid <= 3) &&
		($statetype eq 'HARD' || $statetype eq 'SOFT') &&
		defined($service) &&
		defined($output) &&
		defined($hostname) &&
		defined($hostalias)
	) { 
		# If everything is OK then execution should continue on as normal
		return;
	} else {
		# If one or more arguments were missing, just error out
		usage();
	}
}

sub updatePortal {
	my ($body,$header);
	my $body = "arg=$customer\$$portal_severity\$$portal_message";
	$header.= "POST /portal/bin/notificationCGI.pl HTTP/1.0\r\n";
	$header.= "Content-Type: application/x-www-form-urlencoded\r\n";
	$header.= 'Content-Length: '.length($body)."\r\n\r\n";
	# Now setup socket
	socket(FH,PF_INET,SOCK_STREAM,getprotobyname('tcp')) || die "Unable to create socket: $!";
	my $sin = sockaddr_in(80,inet_aton($portal_ip));
	eval {
		local $SIG{ALRM} = sub { die 'timeout' };
		alarm(5);
		connect(FH,$sin) || die "Connect error: $!";
		send(FH,$header,0);
		send(FH,$body,0);
		alarm(0);
	};
	if ($@ =~ /^timeout/) {
		die 'Connection timed out';
	} elsif ($@ =~ /Connection refused/) {
		die 'Connection refused';
	} elsif ($@) {
		die "Eval error: $@";
	}
	close(FH) || die "Unable to close socket: $!";
}

sub usage {
	print "Usage: $0 -mode <H|S> -cust <customer abbrev> -stateid <0-3> -statetype <HARD|SOFT> ",
		'-service <service name> -output <service output> -host <hostname> -hostalias <host alias>',
		"\n";
	exit 3; # Use the unknown exit code, for what it's worth (at least we can be consistent)
}
