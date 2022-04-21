#!/usr/bin/perl
use strict;

use Net::SSH::Expect;

#----- Global ----------------------------------------------------------------
my %opt;
my $command;
my $logpath;
my $password;
my $server;
my $username;


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init {
	use Getopt::Std;

	# Validate args and load the opt hash:
	my $opt_string = 'c:l:hp:s:u:';
	getopts( "$opt_string", \%opt ) or usage_exit();

	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

    # Exit if required args are missing:
    if (!$opt{c} || !$opt{l} || !$opt{p} || !$opt{s} || !$opt{u}) {
    print "\n";
        print "*** Please provide the required arguments. ***\n";
        print "\n";
        usage_exit();
    }

	# Passed all argument checks. Load the variables:
	$command  = $opt{c} if $opt{c};
	$logpath  = $opt{l} if $opt{l};
	$password = $opt{p} if $opt{p};
	$server   = $opt{s} if $opt{s};
	$username = $opt{u} if $opt{u};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit {
	print STDERR << "EOF";

Send a single command to a host and log to a file called "host.log". This allows
for commands to be run in parallel from the sendcmd.sh wrapper.

Usage: 
    $0 -u username -l logpath -p password -s server -c "command"

    $0 -h  --> Show this usage.

	eg.
	
	$0 -u jrandom -p secret -l /tmp -s 10.24.81.21 -c "sudo /u01/app/adminscripts/grantRoot.sh"
	
EOF
	exit (1);
}


#----- Main ------------------------------------------------------------------
init();

# Sanity check logpath
if (! -d $logpath) {
	system( "mkdir -p $logpath 2>/dev/null" );
}

my $ssh = Net::SSH::Expect->new (
	host        => $server, 
	password    => $password, 
	user        => $username, 
	timeout     => 5,
	no_terminal => 1
);

my $output = $ssh->login( my $test_success );
$output = $ssh->exec( $command );

open( LOG, ">$logpath/$server.log" ) ||
	die "** ERROR ** Unable to open [$logpath/$server.log] for output: $!\n";
print LOG $output;
close( LOG );

exit (0);