#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::item;
use lib::company;
use lib::property;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $itemname = '';


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'h:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Exit if any of the required args are missing:
	if (!$opt{h}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Passed all argument checks. Load the variables:
	$itemname =  $opt{h} if $opt{h};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Show the all the fields for a given item.

usage: 
    $0 -h itemname

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------
init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


my $item = lib::item::getItem( $dbh, $itemname );
print "[$itemname]\n";
foreach my $key (sort keys( %{$item} )) {
	print "    $key = $item->{$key}\n";
}


dao::saconnect::disconnect( $dbh );



exit (0);
