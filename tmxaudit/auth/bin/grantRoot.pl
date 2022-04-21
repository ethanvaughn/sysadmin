#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::sendcmd;


#----- Global ----------------------------------------------------------------
my $username  = "";
my $password  = "";
my $hours     = "";
my $listfile  = "";
my @hosts     = ();


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init {
	use Getopt::Std;

	# Validate args and load the opt hash:
	my $opt_string = 'f:ht:u:';
	getopts( "$opt_string", \%opt ) or usage_exit();

	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

    # Exit if required args are missing:
    if (!$opt{f} or !$opt{t}) {
    print "\n";
        print "*** Please provide the required arguments. ***\n";
        print "\n";
        usage_exit();
    }

	# Passed all argument checks. Load the variables:
	$username = $opt{u} if $opt{u};
	$hours    = $opt{t} if $opt{t};
	$listfile = $opt{f} if $opt{f};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit {
	print STDERR << "EOF";

Wrapper for the sendcmd.exp expect script. This script will prompt for password, 
then execute the "/u01/app/adminscripts/grantRoot.sh" command on each server in 
the listfile. 

Usage: 
    $0 [-u username] -t hours -f listfile

    $0 -h  --> Show this usage.

    Example:

        $0 -u jrandom -t 48 -f /tmp/servers.list

EOF
	exit( 1 );
}


#----- Main ------------------------------------------------------------------
init();
# Sanity check on the listfile:
if ( ! -f $listfile ) {
	print "\n";
	print "*** ERROR *** File not found: $listfile\n";
	print "\n";
	usage_exit();
}


print "\n**** Grant Root Access ****\n\n";

if ($username eq "") {
	print "Datacenter username: ";
	chomp( $username = <STDIN> );
}

$password = lib::sendcmd::pwdprompt();

my $command = "sudo /u01/app/adminscripts/grantRoot.sh $hours";
lib::sendcmd::sendcmd( $username, $password, "$command", $listfile );


exit (0);
