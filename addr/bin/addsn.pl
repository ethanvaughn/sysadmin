#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::sn;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $rec;

# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'c:hm:n:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	if (!$opt{c} or !$opt{m} or !$opt{n}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Passed all argument checks. Load the variables:
	$rec->{comment} = $opt{c} if $opt{c};
	$rec->{mask}    = $opt{m} if $opt{m};
	$rec->{net}     = $opt{n} if $opt{n};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

usage: 
    $0 -n net -m mask -c "comment goes here"

    $0 -h  --> Show this usage.


examples:
 
    $0 -n 10.24.48.0 -m 255.255.255.0 -c "WDC TMX Storage Network VLAN 404"

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------
init();

my $dbh = dao::saconnect::connect();
if (!$dbh) {
	print STDERR "Unable to connect to database.";
	exit (1);
}

lib::sn::addSn( $dbh, $rec );

if ($dbh) {
	dao::saconnect::disconnect( $dbh );
}

exit (0);
