#!/usr/bin/perl
#
#       notifyonoff.pl - S05232006E
#	Called by notifyonoff email alias
#

use strict;
my ($host,$hostgroup,$source,$service,$action);

while(<STDIN>) {
	if (/^HOST:/) {
		$_ =~ s/HOST: //;
		$host=$_;
		chomp ($host);
		next;
	}

	if (/^HOSTGROUP:/) {
		$_ =~ s/HOSTGROUP: //;
		$hostgroup=$_;
		chomp ($hostgroup);
		next;
	}

	if (/^SOURCE:/) {
		$_ =~ s/SOURCE: //;
		$source=$_;
		chomp ($source);
		next;
	}

	if (/^SERVICE:/) {
		$_ =~ s/SERVICE: //;
		$service=$_;
		chomp ($service);
		next;
	}

	if (/^ACTION:/) {
		$_ =~ s/ACTION: //;
		$action=$_;
		chomp ($action);
		next;
	}
}


my $now=time();
chomp ($now);

open (NAGPIPE, ">/u01/app/nagios/var/rw/nagios.cmd");

if ($action eq "ENABLE_HOST_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOST_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host\n";

} elsif ($action eq "ENABLE_HOSTGROUP_SVC_NOTIFICATIONS" || $action eq "DISABLE_HOSTGROUP_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$hostgroup\n";

} elsif ($action eq "ENABLE_SVC_NOTIFICATIONS" || $action eq "DISABLE_SVC_NOTIFICATIONS") {
	print NAGPIPE "[$now] $action;$host;$service\n";
	
} else {
	exit 0
}

close (NAGPIPE);
