#!/usr/bin/perl

use strict;
use LWP 5.64;
my $browser = LWP::UserAgent->new;



#----- Global ----------------------------------------------------------------
my %opt = ();
my $cgihost  = "localhost";
my $hostname = "testhostname";
my $level    = "CRIT";
my $service  = "Test Service";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init {
	use Getopt::Std;

	# Validate args and load the opt hash:
	my $opt_string = 'c:hl:s:n:';
	getopts( "$opt_string", \%opt ) or usage_exit();

	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

    # Exit if required args are missing:
#    if (!$opt{f} or !$opt{t}) {
#    print "\n";
#        print "*** Please provide the required arguments. ***\n";
#        print "\n";
#        usage_exit();
#    }

	# Passed all argument checks. Load the variables:
	$cgihost  = $opt{c} if $opt{c};
	$hostname = $opt{n} if $opt{n};
	$level    = $opt{l} if $opt{l};
	$service  = $opt{s} if $opt{s};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit {
	print STDERR << "EOF";

Create a test record in the MAL database.

Usage: 
    $0 [-c cgihost] [-s servicename] [-n hostname] [-l level]

    $0 -h  --> Show this usage.

	cgihost     -- Defaults to "localhost". IP Address or hostname of the host
                   to use in the URL. 
	servicename -- Defaults to "Test Service"
    hostname    -- Defaults to "testhostname".
    level       -- Defaults to "CRIT". Can be CRIT or WARN.

    Example:

        $0 

EOF
	exit( 1 );
}


#----- Main ------------------------------------------------------------------
init();

print STDERR "DEBUG: level = $level\n";
if ($level ne "CRIT" and $level ne "WARN") {
	print STDERR "\nUnknown level. Must be CRIT or WARN.\n";
	usage_exit;
}

my $url = "http://$cgihost/mal-x/alert";

my $response = $browser->post( $url,
	[
		hostname    => $hostname, 
		servicename => $service, 
		ip          => "10.24.74.56",
		msg         => $level . ": Log Error 602: Test log entry that has multiple lines.\nThis is line 2.\nAnd this is line 3.",
		level       => $level
	]
);

die "$url error: ", $response->status_line
	unless $response->is_success;


print $response->content;

exit 0;
