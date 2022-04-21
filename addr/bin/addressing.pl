#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::sn;
use lib::ip;
use lib::ipfunc;
use lib::item;

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
my $subnet;

# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'hs:';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});
	
	# Passed all argument checks. Load the variables:
    $subnet = $opt{s} if $opt{s};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
	print STDERR << "EOF";

Flat list of all addressing information in sections by subnet.

usage: 
    $0 [-s subnet] 

          subnet = network address for individual subnet display

    $0 -h  --> Show this usage.

EOF

	exit( 1 );
}



#----- printsnheader --------------------------------------------------------------
sub printsnheader {
	my $rec  = shift;
	my $cidr = shift;
	
	print "==============================================================================\n";
	print "$rec->{net}/$cidr\n";
	print "$rec->{mask}\n";
	print "$rec->{comment}";
	print "\n\n";

	printf "%-15.15s %-9.9s %-15.15s %-15.15s [%s] : [%s]\n",
		"IP ADDR",
		"TYPE",
		"USERS",
		"HOSTNAME",
		"IP COMMENT",
		"ITEM COMMENT";
	print "--------------- --------- --------------- --------------- ------------------------------------\n";
} 



#----- printsn ---------------------------------------------------------------
sub printsn {
	my $dbh = shift;
	my $rec = shift;

	my $cidr = lib::ipfunc::int2cidr( lib::ipfunc::ip2int( $rec->{mask} ) );
	
	printsnheader( $rec, $cidr );
	
	# Get the full list of addressesssess for this subnet
	my $netint = lib::ipfunc::ip2int( $rec->{net} );
	my $iplist = lib::ipfunc::getIPList( $netint, $cidr );
	
	# Get a list of addresses assigned to this subnet:
	my $db_iplist = lib::ip::getIpListBySn( $dbh, $rec->{id} );

	foreach my $ip (@$iplist) {			
		# Clear the hash of row data:
		my $rowrec = 0;

		# The first element in @iplist is the network address, the last is broadcast:
		if ($ip == @$iplist[0]) {
			printf "%-15.15s %s\n",
				lib::ipfunc::int2ip( $ip ),
				"NETWORK";
			next;
		}
		my @tmp = @$iplist;
		if ($ip == @$iplist[$#tmp]) {
			printf "%-15.15s %s\n",
				lib::ipfunc::int2ip( $ip ),
				"BROADCAST";
			next;
		}

		# Set ip to human readable value:
		$ip =  lib::ipfunc::int2ip( $ip );
		
		my $found_in_db = 0;
		foreach my $dbrec (@$db_iplist) {
			my $users;
			if ($dbrec->{ipaddr} eq $ip) {
				$found_in_db = 1;

				# Get the User info for the item that uses this IP:
				if ($dbrec->{itemname}) {
					my $list = dao::item::getItemUsers( $dbh, $dbrec->{itemname} );
					foreach my $key (sort keys( %{$list} )) {
						$users .= $list->{$key}->{code} . '-';
					}
					chop( $users );
				}
				
				# Get the currently selected type:
				my $type_rec;
				my $type_id = lib::ip::getTypeLink( $dbh, $dbrec->{id} );
				if ($type_id) {
					$type_rec = lib::ip::getIpTypeById( $dbh, $type_id );
				}

				printf "%-15.15s %-9.9s %-15.15s %-15.15s [%s] : [%s]\n",
					$dbrec->{ipaddr},
					$type_rec->{name},
					$users,
					$dbrec->{itemname},
					$dbrec->{comment},
					$dbrec->{item_comment};
			} 
			last if $found_in_db;
		}
		print $ip . " \n" if (! $found_in_db);
	} #iplist
	
} 



#----- Main ------------------------------------------------------------------
init();

my $dbh = dao::saconnect::connect();
if (!$dbh) {
	print STDERR "Unable to connect to database.";
	exit (1);
}


my $snlist = lib::sn::getSnList( $dbh );
foreach my $rec (@$snlist) {
	if ($subnet) {
		if ($subnet eq $rec->{net}) {
			printsn( $dbh, $rec );
			last;
		}
		next;
	}
	printsn( $dbh, $rec );
	# whitespace between subnet blocks
	print "\n\n";

} #snlist


if ($dbh) {
	dao::saconnect::disconnect( $dbh );
}

exit (0);
