#!/usr/bin/perl

use strict;
use Net::SNMP;

# Globals
my ($host,$tunnel_peer);
my $oid = '1.3.6.1.4.1.3076.2.1.2.17.2.1.4';

validateArgs();
queryHost();

sub queryHost {
	my $session = Net::SNMP->session(-timeout=>5,-hostname=>$host,-community=>'public',-port=>161);
	# Now query
	my $tunnels_ref = $session->get_table($oid);
	if (ref($tunnels_ref) ne 'HASH') {
		print "CRITICAL: Unable to connect to $host";
		exit 2;
	}
	my %tunnels = reverse(%$tunnels_ref);
	# Debugging
	#foreach my $ip (keys(%tunnels)) {
	#	print "$ip\n";
	#}
	if (exists($tunnels{$tunnel_peer})) {
		print "OK: VPN Tunnel active for Peer $tunnel_peer";
		exit 0;
	} else {
		print "CRITICAL: VPN Tunnel inactive for Peer $tunnel_peer";
		exit 2;
	}
	$session->close();
		
}

sub validateArgs {
	if (length($ARGV[0]) != 0 || length($ARGV[1]) != 0) {
		($host,$tunnel_peer) = @ARGV;
	} else {
		print "Usage: $0 <IP of Cisco VPN 3k to query> <tunnel peer IP>\n";
		exit 1;
	}
}
