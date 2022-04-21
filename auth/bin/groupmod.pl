#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::updategroup;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $newname = "";
my $groupname = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'n:h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	if (!$opt{n}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Exit if ARGV now has more than 1 arg:
	# (this should be the user login name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$newname = $opt{n} if $opt{n};
	$groupname = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Modify group attributes.

usage: 
    $0 -n newgroupname groupname

    $0 -h  --> Show this usage.


examples: 
    $0 -n wheel sysadmin
    This command will rename the "sysadmin" group to "wheel".

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

lib::updategroup::setGroupName( $dbh, $groupname, $newname );
my $errstr = $dbh->errstr;
($errstr) && die "$errstr. Changing group [$groupname] to [$newname].\n";

dao::saconnect::disconnect( $dbh );

exit (0);
