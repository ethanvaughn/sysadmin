#!/usr/bin/perl -w

use Socket;

use strict;


# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $cust = "";
my $env = "";
my $type = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Passed all argument checks. Load the variables:
#	$cust = $opt{c} if $opt{c};
#	$env = $opt{e} if $opt{e};
#	$type = $opt{t} if $opt{t};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Get a list of unacknowledged host and service events.

usage: 
    $0 

    $0 -h  --> Show this usage.

	
examples: 
	List all unacknowledged events:
    $0  

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

# initialize host and port
my %hosts = ( "wdc" => "10.24.74.9", "sdc" => "10.9.15.10" ); 
my $port = 80;
my $proto = getprotobyname('tcp');

my @list = ();

# Set up the query string:
#my $qry = "";
#print "DEBUG: qry = [$qry]\n";

# Set up the HTTP request:
my $request = <<REQ;
GET /nquery/listunack HTTP/1.0
Accept: */*
User-agent: $0

REQ

# Connect and load the list for each server:
foreach my $host (keys(%hosts)) {
#	print "host = $host [$hosts{$host}]\n";

	my $paddr = sockaddr_in( $port, inet_aton( $hosts{$host} ) );

	# create the socket, connect to the port
	socket( SOCKET, PF_INET, SOCK_STREAM, $proto ) 
		or die "Unable to open socket to [$hosts{$host}:$port]: $!";

	connect( SOCKET, $paddr ) 
		or die "Unable to connect to [$hosts{$host}:$port]: $!";

	send( SOCKET, $request, 0 )
		or die "Unable to send HTTP Request: $!";

	# Unbuffer the output:
	$| = 1;

	# Get the output and close the socket:
	my @output = <SOCKET>;
	close SOCKET 
		or die "Unable to close socket to [$hosts{$host}:$port]: $!";
	
	foreach my $line (@output) {
		if ($line =~ /[|]/) {
			push( @list, $host."|".$line );
		}
	} 
}


foreach (@list) {
	print;
}

exit (0);

