#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::getgroup;
use lib::updategroup;


use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $gid = "";
my $groupname = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'g:h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if ARGV now has more than 1 arg:
	# (this should be the gropu name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$gid = $opt{g} if $opt{g};
	$groupname = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Add group to the tmxaudit database.

usage: 
    $0 [-g gid] groupname

    $0 -h  --> Show this usage.


examples: 
    $0 sysadmin
    $0 -g 40003 dev 

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


if (!$gid) {
	# Get next id from the posixgroup table:
	$gid = lib::getgroup::getNextGid( $dbh );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: Unable to get next GID: $errstr\n";
}

lib::updategroup::addGroup( $dbh, $gid, $groupname );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to add group [$groupname]: $errstr\n";

dao::tmxconnect::disconnect( $dbh );

# Update auth files for all hosts:
`$Bin/mkclientdata.pl`;

exit (0);
