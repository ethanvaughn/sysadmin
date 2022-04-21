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
	my $opt_string = 'hic:e:nt:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Passed all argument checks. Load the variables:
	$cust = $opt{c} if $opt{c};
	$env = $opt{e} if $opt{e};
	$type = $opt{t} if $opt{t};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Get a list of Nagios managed hosts.

usage: 
    $0 [-i] [-n] [-c "cust_code"] [-e "env_code"] [-t "type_code"]

    $0 -h  --> Show this usage.

	
examples: 
	List all hosts:
    $0  

	List all hosts for customer "Kelly Moore":
	$0 -c "km"

	List all lab hosts for customer "Kelly Moore":
	$0 -c "km" -t "lab"

	List all lab hosts and show IP addresses:
	$0 -i -t "lab"

	List status summary for customer 'Ratner'
	$0 -n -c "cust"

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

# initialize host and port
my @hosts = ( "10.24.74.9", "10.9.15.10" );
my $port = 80;
my $proto = getprotobyname('tcp');

my @list = ();

# Set up the query string:
my $qry = "";
if ($opt{c} or $opt{e} or $opt{t} or $opt{i} or $opt{n}) { 
	$qry = "?"; 
}
if ($opt{c}) {
	$qry .= "cust=$opt{c}";
}
if ($opt{e}) {
	if ($opt{c}) { $qry .= "&"; }
	$qry .= "env=$opt{e}";
}
if ($opt{t}) {
	if ($opt{c} or $opt{e}) { $qry .= "&"; }
	$qry .= "type=$opt{t}";
}
if ($opt{i}) {
	if ($opt{c} or $opt{e} or $opt{t}) { $qry .= "&"; }
	$qry .= "ip=1";
}
if ($opt{n}) {
	if ($opt{c} or $opt{e} or $opt{t} or $opt{i}) { $qry .= "&"; }
	$qry .= "info=1";
}
#print "DEBUG: qry = [$qry]\n";

# Set up the HTTP request:
my $request = <<REQ;
GET /nquery/listhosts$qry HTTP/1.0
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


# Parse the output. 
# Here we want to skip the http headers and just print the data list.
# Skip everything upto and including the first empty line.
my $hdrdone = 0;
foreach my $line (@list) {
	if ($line =~ /\r\n/) {
		$hdrdone = 1;
		next;
	}
	if ($hdrdone) {
		print $line;
	}
}


exit (0);
