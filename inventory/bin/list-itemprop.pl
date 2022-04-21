#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::item;

use strict;


#----- Main ------------------------------------------------------------------

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


my $data = lib::item::getItemList( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Database error getItemList: $errstr\n";

printf "%-20.20s %-20.20s %-38.38s\n", "Item Name", "Serial No.", "Comment";
print "-------------------- -------------------- ----------------------------------------\n";
foreach my $row (@$data) {
	printf "%-20.20s %-20.20s %-38.38s\n", $row->{itemname}, $row->{serialno}, $row->{comment};
}


dao::saconnect::disconnect( $dbh );

exit (0);
