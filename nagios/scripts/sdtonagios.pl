#!/usr/bin/perl

use strict;
use DBI;

# Globals
my @acks; # Array of hashes of events to ACK
my $nagios = '/u01/app/nagios/var/rw/nagios.cmd'; # Location of named pipe to write to


readInput();
ackEvents();
updateDB();

sub updateDB {
	my $c = DBI->connect('DBI:mysql:tickets;mysql_multi_results=1','tickets','t1ck3ts');
        if ($DBI::errstr) {
                warn "Unable to connect to MySQL DB: $!";
        } else {
		my $rs;
		foreach my $event (@acks) {
			# Same sanity check as ackEvents...
			if (ref($event) ne 'HASH') {
				next;
			}
			if ($event->{type} eq 'H') {
				$rs = $c->prepare("call tickets.ack_sd_host_ticket($event->{hostname})");
				$rs->execute();
			} elsif ($event->{type} eq 'S') {
				print "call tickets.ack_sd_service_ticket('$event->{hostname}','$event->{service}')";
				$rs = $c->prepare("call tickets.ack_sd_service_ticket('$event->{hostname}','$event->{service}')");
				$rs->execute();
			} else {
				next;
			}
		}
        }
	$c->disconnect() if $c;
}

sub ackEvents {
	# First check and make sure the named pipe exists
	# If it doesn't and we continue, Perl would create it, which is NOT what we want
	# This is a sanity check since the named pipe only exists WHILE Nagios is running
	if (!(-e $nagios)) {
		return; 
	}
	open(NAGIOS,">>$nagios") || die "Unable to open $nagios: $!";
	foreach my $event (@acks) {
		# Skip if we somehow don't have a hash ref here (safeguard!)
		if (ref($event) ne 'HASH') {
			next;
		}
		my $str;
		# See Nagios docs for an explanation of what these do
		# Service ACK: http://www.nagios.org/developerinfo/externalcommands/commandinfo.php?command_id=401
		# Host ACK: http://www.nagios.org/developerinfo/externalcommands/commandinfo.php?command_id=39
		# For readability str is built across a couple lines
		if ($event->{type} eq 'S') {
			$str = '['.time().'] ACKNOWLEDGE_SVC_PROBLEM;';
			$str.= $event->{hostname}.';'.$event->{service}.';0;1;0;Service Desk;ACK by SD User';
			print NAGIOS $str."\n";
			# Do not make any more checks: move to next hash
			next;
		}
		if ($event->{type} eq 'H') {
			$str = '['.time().'] ACKNOWLEDGE_HOST_PROBLEM;';
			$str.= $event->{hostname}.';0;1;0;Service Desk;ACK by SD User';
			print NAGIOS $str."\n";
			# Do not make any more checks: move to next hash
			next;
		}
	}
	close(NAGIOS);
}

sub readInput {
        my $timeout = 5; # How long to wait before giving up
        my $status = 0;
        eval {
                local $SIG{ALRM}=sub { die "timeout"; };
                alarm $timeout;
                while(<STDIN>) {
			chomp;
                        if ($status == 0) {
				# Status is 0 until we hit a BEGIN block
				if (/^BEGIN/) {
					$status = 1;
					next;
				}
                        }
                        if ($status == 1) {
				my %event;
				my @line = split(/_/);
				# Safeguards:
				#  a valid HOST event must contain HOST_<hostname> (2)
				#  a valid SERVICE event must contain SERVICE_<hostname>_<service desc> (3)
				if (scalar(@line) == 2 && $line[0] eq 'HOST') {
					$event{type} = 'H';
					$event{hostname} = $line[1];
				} elsif (scalar(@line) == 3 && $line[0] eq 'SERVICE') {
					$event{type} = 'S';
					$event{hostname} = $line[1];
					$event{service} = $line[2];
				} else {
					# This is unknown gobbly-gook
					next;
				}
				# Now add this hash to our list
				push(@acks,\%event);
				# Don't run any more regexs: skip to next line
				next;
                        }
			if (/^END/) {
				# We've reached the end of events to ACK
				last;
			}
                }
                alarm 0;
        };
        if (!(defined(@acks))) {
                #die "No events to ACK found"; # Commented out for now to prevent bounces
		exit 0; # Why die when you can just happily exit?
		
        }
}
