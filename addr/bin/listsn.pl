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


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Flat list of all subnet information.

usage: 
    $0 

    $0 -h  --> Show this usage.

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

my $list = lib::sn::getSnList( $dbh );

print "id,net,mask,comment\n";
foreach my $rec (@$list) {
	print "$rec->{id},$rec->{net},$rec->{mask},$rec->{comment}\n";
}


if ($dbh) {
	dao::saconnect::disconnect( $dbh );
}

exit (0);
