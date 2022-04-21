#!/usr/bin/perl 

use Term::ReadKey;

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::passwdutils;
use dao::saconnect;
use lib::updateaccount;

use strict;

# ----- Global ---------------------------------------------------------------
# Policy: number of passwords to keep in the history:
my $MAX = 5;
# Set number of retries for password prompt.
my $RETRIES = 3;
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $username = "";
my $password = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'hp:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if ARGV now has more than 1 arg:
	# (this should be the user login name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$username = $ARGV[0];
	$password = $opt{p} if $opt{p};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Set user's password.

usage: 
    $0 [-p "password"] username

    $0 -h  --> Show this usage.


examples: 
    $0 evaughn 
       Enter password:
       Re-type password:
       Password updated successfully.

    $0 -p "Erp3djkj" jrandom  
       Password updated successfully.

    $0 jrandom -p "Erp3djkj"
       Password updated successfully.

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

print "Changing password for $username.\n";

# Check environment for user. If root, no need to authenticate:
if ($ENV{LOGNAME} ne "root") {
	# Authenticate old (current) password
	for (my $i=0; $i<($RETRIES + 1); $i++) {
		if ($i >= $RETRIES) {
			print "\nAuthentication failed. Password not changed.\n";
			exit( 1 );
		}
		print "Old (current) password: ";
		ReadMode 2;
		chomp( my $old = <STDIN>);
		ReadMode 1;
		print "\n";
		if (lib::passwdutils::authenticate( $dbh, $username, $old )) {
			last;
		} else {
			print "Unable to authenticate. Please re-enter.\n";
		}
	}
}

# Get password and validate
if ($password == "") {
	my $password2 = "";

	# Prompt for new password
	for (my $i=0; $i<($RETRIES + 1); $i++) {
		if ($i >= $RETRIES) {
			print "\nUnable to set password. Not changed.\n";
			exit( 1 );
		}
		print "Enter (new) password: ";
		ReadMode 2;
		chomp( $password = <STDIN>);
		ReadMode 1;
		print "\n";
		print "Re-type password: ";
		ReadMode 2;
		chomp( $password2 = <STDIN>);
		ReadMode 1;
		print "\n";
		if ( $password ne $password2 ) {
			print "Passwords do not match. Please re-enter.\n";
		} else {
			last;
		}
	}		
}

my $errstr = lib::passwdutils::validatePassword( $dbh, $username, $password );
if ($errstr) {
	dao::saconnect::disconnect( $dbh );
	die "$errstr. Password not changed.\n";
}

lib::updateaccount::setPassword( $dbh, $username, $password );
my $errstr = $dbh->errstr;
if ($errstr) {
	dao::saconnect::disconnect( $dbh );
	die "$errstr. Password not changed.\n";
}

dao::saconnect::disconnect( $dbh );

exit (0);
