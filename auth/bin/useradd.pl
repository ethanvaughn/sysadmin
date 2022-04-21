#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::getaccount;
use lib::getgroup;
use lib::updateaccount;
use lib::updategroup;


use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $listfile = "";
my $fname = "";
my $homedir = "";
my $gname = "";
my $uid = "";
my $username = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'f:c:d:g:hu:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	#if (!$opt{c} or !$opt{d} or !$opt{g}) {
	if (!$opt{c}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Exit if ARGV now has more than 1 arg:
	# (this should be the user login name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$listfile = $opt{f} if $opt{f};
	$fname = $opt{c} if $opt{c};
	$homedir = $opt{d} if $opt{d};
	$gname = $opt{g} if $opt{g};
	$uid = $opt{u} if $opt{u};
	$username = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Add user to the tmxaudit database.

usage: 
    $0 [-f listfile] -c "Full Name" [-d home_dir] [-g primary_group] [-u uid] username

    $0 -h  --> Show this usage.


examples: 
    $0 -c "Jay Random" -g sysdba -d /u01/home/sysdba/jrandom jrandom

	Note: Run ./mkgroup.pl to view the list of available groups.

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


if (!$uid) {
	$uid = lib::getaccount::getNextUid( $dbh );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: Unable to get next UID: $errstr\n";
}

my $gid = "101"; # Default to 101 'dba'
# If $gname from command-line is non-numeric, try a lookup ... 
if ($gname =~ /\D+/) {
	$gid = lib::getgroup::getGidByName( $dbh, $gname );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: Unable to get GID for [$gname]: $errstr\n";
} else {
	# .. otherwise keep the literal numeric value from command-line.
	$gid = $gname;
}	


lib::updateaccount::addAccount( $dbh, $uid, $gid, $homedir, $fname, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to add account [$username]: $errstr\n";

lib::updateaccount::resetpwd( $dbh, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to reset password [$username]: $errstr\n";

dao::saconnect::disconnect( $dbh );

`$Bin/send-reset-email.pl $username`;

exit (0);
