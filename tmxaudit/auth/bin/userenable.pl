#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::updateaccount;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $username = "";


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
	$username = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Enable an expired user account.

usage: 
    $0 username

    $0 -h  --> Show this usage.


examples: 
    $0 jrandom
       Account jrandom enabled.

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


lib::updateaccount::enable( $dbh, $username );
my $errstr = $dbh->errstr;
if ($errstr) {
	dao::tmxconnect::disconnect( $dbh );
	die "$errstr. Account not changed.\n";
}

dao::tmxconnect::disconnect( $dbh );

print "User account $username enabled.\n\n";

# Update auth files for all hosts:
`$Bin/mkclientdata.pl`;

exit (0);
