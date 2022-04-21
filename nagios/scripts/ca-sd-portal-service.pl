#!/usr/bin/perl

use strict;
use DBI;
use Getopt::Long;


# Incoming arguments
my ($customer,$status,$hostname,$hostdesc,$servicedesc,$serviceoutput,$type);

# Globals

my $message;
my $severity;
my $ticket;
GetOptions('status=i' => \$status, 'H=s' => \$hostname, 'Hdesc=s' => \$hostdesc, 'S=s' => \$servicedesc, 'Soutput=s' => \$serviceoutput, 'C=s' => \$customer, 'T=s' => \$type);

if (!($customer && defined($status) && $hostname && $hostdesc && $servicedesc && $serviceoutput && $type)) {
	print "Usage: $0 -C <CA customer> -H <hostname> -Hdesc <host description> -S <service description> -Soutput <service output> -status <0|1|2|3> -T <HARD|SOFT>\n";
	exit 1;
}


# Fix ()s (Disk Usage plugin returns $serviceoutput with ()s in it, which jacks up portal.  So remove them here
$serviceoutput =~ s/\(|\)//g;

# Status codes:
# 0 = OK
# 1 = WARNING
# 2 = CRITICAL
# 3 = UNKNOWN (UNKNOWN is treated the same as critical)

if ($status == 0) {
	# Update portal and close tickets (if applicable)
	$severity = 1;
	$message = "$hostname - $hostdesc - $servicedesc is OK: $serviceoutput";
	closeTicket();
} elsif ($status == 1) {
	if ($type eq 'HARD') {
		$severity = 2;
		$message = "$hostname - $hostdesc - $servicedesc is WARNING: $serviceoutput";
		createTicket();
	} else {
		exit 0;
	}
} elsif ($status == 2) {
	if ($type eq 'HARD') {
		$severity = 3;
		$message = "$hostname - $hostdesc  - $servicedesc is CRITICAL: $serviceoutput";
		createTicket();
	} else {
		exit 0;
	}
} elsif ($status == 3) {
	if ($type eq 'HARD') {
		$severity = 3;
		$message = "$hostname - $hostdesc - $servicedesc is UNKNOWN: $serviceoutput";
		createTicket();
	} else {
		exit 0;
	}
} else {
	# unknown state: exit
	exit 0;
}

sub closeTicket {
	# Works as follows
	# 1) Get Ticket Number from MySQL
	# 2) Closes ticket in SD
	# 3) Update CA Portal

	# Get MySQL Ticket Number
	# a) connect to MySQL
	# Setup Database Connection
  	my $c = DBI->connect('DBI:mysql:tickets;mysql_multi_results=1','tickets','t1ck3ts');
	if ($DBI::errstr) {
		warn "Unable to connect to MySQL DB: $!";
	} else {
		# b) call SP to retrieve ticket(s) (the same SP deletes the log event)
		my $rs = $c->prepare("call tickets.get_sd_service_ticket('$hostname','$servicedesc')");
		$rs->execute();
		if ($DBI::errstr) {
			warn "Error executing SP: $!";
		}
		# This is pretty imporant.  Say a ticket is opened when something is in a warning state, then another ticket
		# opens when it goes to a critical state.  When it goes back to OK, we need to close all the tickets.  The SP
		# returns a list of all tickets for that host/service, so loop over all of them and close them
		while (my $href = $rs->fetchrow_hashref()) {
			$ticket = $href->{ticket};
			my $toportal; # What gets sent to the portal
			if (defined($ticket)) {
				$toportal = "Incident $ticket Closed: $message";
				system("ssh root\@10.24.74.10 /root/nagios/nagios_connector.pl -m close -t $ticket -d \\\"$message\\\"");
			} else {
				$toportal = "RESOLVED: $message";
			}
			# Update portal
			system("ssh administrator\@10.24.74.19 cmd.exe /C c:/nagiostoportal.pl $customer $severity $toportal");
		}
		$c->disconnect() if $c;
	}
}
	

sub createTicket {
	# TODO: Need to check and see if we've already created a ticket about this
	# 	Need to think about when SD doesn't respond and other types of circumstances
	# Works as follows
	# 1) Create ticket in SD
	# 2) Read back ticket number
	# 3) Create log event in MySQL DB
	# 4) Update CA portal

	# Create ticket in SD
	# a) needs to be changed to use IO::Select
	# Create ticket
	open(CMD,"ssh root\@10.24.74.10 /root/nagios/nagios_connector.pl -m create -c $customer -d \\\"$message\\\"|");
	# Read back ticket number
	while(<CMD>) {
		if (/TICKET/) {
			chomp;
			my @data = split();
			if ($data[1] =~ /^\d+$/) {
				$ticket = $data[1];
			}
		} 
	}
	close(CMD);
	# Now we should have the ticket number.  If not, skip this step
	if ($ticket) {
		# Create the log event
		# a) connect to MySQL
		# Setup Database Connection
		my $c = DBI->connect('DBI:mysql:tickets;mysql_multi_results=1','tickets','t1ck3ts');
		if ($DBI::errstr) {
			warn "Unable to connect to MySQL DB: $!";
		} else {
			# b) call SP to create log event
			my $rs = $c->prepare("call tickets.create_sd_service($ticket,\"$hostname\",\"$servicedesc\",$status)");
			$rs->execute();
			if ($DBI::errstr) {
				warn "Error executing SP: $!";
			}
		}
		$c->disconnect() if $c; 
		# Add ticket info to $message
		$message = "Incident: $ticket $message";
	}
	# Update CA Portal (with or without ticket number) (commented out during dev -- we know this works!)
	system("ssh administrator\@10.24.74.19 cmd.exe /C c:/nagiostoportal.pl $customer $severity $message");
}
