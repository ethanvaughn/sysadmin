#!/usr/bin/perl

use strict;
use DBI;
use Getopt::Long;


# Incoming arguments
my ($customer,$status,$hostname,$hostdesc,$output,$type);

# Globals

my $message;
my $severity;
my $ticket;
GetOptions('status=i' => \$status, 'H=s' => \$hostname, 'Hdesc=s' => \$hostdesc, 'output=s' => \$output, 'C=s' => \$customer, 'T=s' => \$type);

if (!($customer && defined($status) && $hostname && $hostdesc && $output && $type)) {
	print "Usage: $0 -C <CA customer> -H <hostname> -Hdesc <host description> -output <service output> -status <0|1|2|3> -T <HARD|SOFT>\n";
	exit 1;
}


# Fix ()s (Disk Usage plugin returns $serviceoutput with ()s in it, which jacks up portal.  So remove them here
$output =~ s/\(|\)//g;

# Status codes:
# 0 = UP
# 1 = DOWN
# 2 = UNREACHABLE

if ($status == 0) {
	# Update portal and close tickets (if applicable)
	$severity = 1;
	$message = "$hostname - $hostdesc is UP: $output";
	closeTicket();
} elsif ($status == 1) {
	if ($type eq 'HARD') {
		$severity = 3;
		$message = "$hostname - $hostdesc is DOWN: $output";
		createTicket();
	} else {
		exit 0;
	}
} elsif ($status == 2) {
	if ($type eq 'HARD') {
		$severity = 3;
		$message = "$hostname - $hostdesc is UNREACHABLE: $output";
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
		my $rs = $c->prepare("call tickets.get_sd_host_ticket('$hostname')");
		$rs->execute();
		if ($DBI::errstr) {
			warn "Error executing SP: $!";
		}
		# I'm not sure when it would happen, but it's possible that a host could be down, and then later
		# become unreachable.  If that's the case, and said host comes back online, we want to close both tickets
		# (if they were created) so iterate over all returned results (even though it is likely there will only be one)
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
			my $rs = $c->prepare("call tickets.create_sd_host($ticket,\"$hostname\",$status)");
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
