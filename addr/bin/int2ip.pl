#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::ipfunc;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $arg1 = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if ARGV now has more than 1 arg:
	# (this should be the user login name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$arg1 = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

usage: 
    $0 int

    $0 -h  --> Show this usage.


examples:
 
    $0 169363977
    10.24.74.9

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $val = lib::ipfunc::int2ip( $arg1 );
if (!$val) {
	print STDERR "ERROR: Invalid Integer.\n";
	usage_exit();
}

print $val;
print "\n";

exit (0);
