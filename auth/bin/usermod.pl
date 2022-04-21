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
my $fname = "";
my $homedir = "";
my $gid ="";
my $gname = "";
my $uid = "";
my $username = "";
my $newusername = "";

# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'c:d:g:G:h:l:u:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if ARGV now has more than 1 arg:
	# (this should be the user login name)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$fname = $opt{c} if $opt{c};
	$homedir = $opt{d} if $opt{d};
	$gid = $opt{g} if $opt{g};
	$gname = $opt{G} if $opt{G};
	$uid = $opt{u} if $opt{u};
	$newusername = $opt{l} if $opt{l};
	$username = $ARGV[0];
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Modify a user's account attributes.

Usage: $0 [options] username

Options:
   -c "Full Name"           change value of the GECOS field
   -d /u01/home/sysadmin    change login directory for the user account
   -g gname                 change GID for the user account
   -G sysadmin,dba          delete from all groups and add to these groups
   -h                       display this help message and exit
   -l newusername           change username (not a stackable parameter)
   -u 40001                 change UID for the user account
   
examples: 
$0 -c "Ethan Vaughn" -u 40003 -d /u01/home -g sysadmin evaughn 
$0 -G sysadmin,dba jrandom
$0 -l bob jrandom (changes username of jrandom to bob)

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------

init();

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

# Modify the full name of a user account.
if ($fname) {
my $set_fname = lib::updateaccount::setFullName( $dbh, $fname, $username);
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change full name for [$fname]: $errstr\n";}

# Modify the home directory of a user account.
if ($homedir) {
my $set_homedir = lib::updateaccount::setHomeDirectory( $dbh, $homedir, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change home directory for [$fname]: $errstr\n";}

# Modify the GID of a user account.
if ($gid) {
$gid = lib::getgroup::getGidByName( $dbh, $gid );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to get GID for [$gid]: $errstr\n";

my $set_gid = lib::updateaccount::setGID( $dbh, $gid, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change GID for [$fname]: $errstr\n";}

# Modify the groups of a user account.
if ($gname) {
my $set_gname = lib::updateaccount::setGroups( $dbh, $gname, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change groups for [$fname]: $errstr\n";}

# Modify the UID of a user account.
if ($uid) {
my $set_uid = lib::updateaccount::setUID( $dbh, $uid, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change UID for [$fname]: $errstr\n";}

# Modify the username of a user account.
if ($newusername) {
my $set_newusername = lib::updateaccount::setUsername( $dbh, $newusername, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to change username for [$fname]: $errstr\n";}

dao::saconnect::disconnect( $dbh );

exit (0);
