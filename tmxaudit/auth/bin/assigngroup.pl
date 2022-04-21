#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::updategroup;


use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $groupname = "";
my $username = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'g:hu:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	if (!$opt{g} or !$opt{u}) {
		print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Passed all argument checks. Load the variables:
	$groupname = $opt{g} if $opt{g};
	$username = $opt{u} if $opt{u};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Assign a user to the specified group.

usage: 
    $0 -g group -u username

    $0 -h  --> Show this usage.


examples: 
    $0 -g sysadmin -u evaughn 
    $0 -u jrandom -g testusers

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

lib::updategroup::addUserToGroup( $dbh, $username, $groupname );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to add [$username] to group [$groupname]: $errstr\n";

dao::tmxconnect::disconnect( $dbh );


# Update auth files for all hosts:
`$Bin/mkclientdata.pl`;

exit (0);
