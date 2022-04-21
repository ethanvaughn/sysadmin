#!/usr/bin/perl -w

use Socket;

use strict;



#----- Main ------------------------------------------------------------------

# initialize host and port
my @hosts = ( "10.24.74.9", "10.9.15.10" );
my $port = 80;
my $proto = getprotobyname('tcp');

my @list = ();

# Set the http request:
my $request = <<REQ;
GET /nquery/listtypes HTTP/1.0
Accept: */*
User-agent: $0

REQ


# Connect and load the list for each server:
foreach my $host (@hosts) {
	my $paddr = sockaddr_in( $port, inet_aton( $host ) );

	# create the socket, connect to the port
	socket( SOCKET, PF_INET, SOCK_STREAM, $proto ) 
		or die "Unable to open socket to [$host:$port]: $!";

	connect( SOCKET, $paddr ) 
		or die "Unable to connect to [$host:$port]: $!";

	send( SOCKET, $request, 0 )
		or die "Unable to send HTTP Request: $!";

	# Unbuffer the output:
	$| = 1;

	# Get the output and close the socket:
	my @output = <SOCKET>;
	close SOCKET 
		or die "Unable to close socket to [$host:$port]: $!";

	push( @list, @output );
}

# load the composit list into a hash to get a unique list
my %tmphash;
foreach (@list) {
	$tmphash{$_} = "";
}

# Parse the output. 
# Here we want to skip the http headers and just print the data list.
# Skip everything upto and including the first empty line.
my $hdrdone = 0;
foreach my $line (keys( %tmphash )) {
	if ($line =~ /\r\n/) {
		$hdrdone = 1;
		next;
	}
	if ($hdrdone) {
		print $line;
	}
}


exit (0);
