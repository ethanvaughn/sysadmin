#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use Text::ParseWords;

use dao::saconnect;
use lib::ip;
use lib::Item;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $file;



# ----- normalize_hostname ------------------------------------------------------------
sub normalize_hostname {
	my $hostname = shift;
	$hostname =~ tr/[A-Z]/[a-z]/;
	return $hostname;
}



# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'f:h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	if (!$opt{f}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Passed all argument checks. Load the variables:
	$file = $opt{f} if $opt{f};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

usage: 
    $0 -f file

    $0 -h  --> Show this usage.


examples:
 
    $0 -f 10.24.74.0-wdcmgmt

EOF

	exit( 1 );
}



#----- Main ------------------------------------------------------------------
init();

open( FILE, "<$file" ) ||
	die "Unable to open file [$file] for read: $!\n";

my $dbh = dao::saconnect::connect();
if (!$dbh) {
	print STDERR "Unable to connect to database.";
	exit (1);
}

my $count = 0;
my $iprec;
my $itemrec;
my $subnet_id;
my $hostname;
my $typeid;
while (<FILE>) {
	$itemrec = {};
	$iprec = {};

	if ($count == 0) {
		# First line of the file is the subnet id ...
		(my $junk, $subnet_id) = split( /,/, $_ );
		chomp( $subnet_id );
	} else {
		$iprec->{subnet_id} = $subnet_id;
		
		($iprec->{ipaddr}, $typeid, $hostname, $iprec->{comment}) = quotewords( ",", 0, $_ );
		chomp( $iprec->{ipaddr} );
		chomp( $typeid );
		chomp( $hostname );
		chomp( $iprec->{comment} );
		
		if (!$iprec->{ipaddr}) {
			next;
		}
		
		$hostname = normalize_hostname( $hostname ) if ($hostname);
		$itemrec = lib::Item::getItemByName( $dbh, $hostname );
		
		if ($itemrec->{id}) {
			$iprec->{Item_id} = $itemrec->{id};
		}
		
		lib::ip::addIp( $dbh, $iprec );
		
		print "Added: [";
		print $iprec->{ipaddr};
		print "] [";
		print $iprec->{comment};
		print "] [";
		print $iprec->{Item_id};
		print "] [";
		print $iprec->{subnet_id};
		print "]\n";
		
		# Get the ipaddr id of the record we just added:
		$iprec = lib::ip::getIpByAddr( $dbh, $iprec->{ipaddr} );

		# Insert the iptypelink ...
		lib::ip::setTypeLink( $dbh, $iprec->{id}, $typeid );
		
	}

	 
	
	$count++;
}

close( FILE );


#lib::sn::addSn( $dbh, $rec );

#if ($dbh) {
#	dao::saconnect::disconnect( $dbh );
#}

exit (0);
