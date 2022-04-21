#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::item;

use strict;

#----- Globals ----------------------------------------------------------------
my $item_type = "SERVER";
if ($ARGV[0]) {
	$item_type = $ARGV[0];
}


#----- Main ------------------------------------------------------------------
my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


my $data = lib::item::getItemListByType( $dbh, $item_type );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Database error getItemListByType: $errstr\n";

foreach my $row (@$data) {
	#printf "%-20.20s %-20.20s %-38.38s\n", $row->{itemname}, $row->{serialno}, $row->{comment};
	print "$row->{ipaddr}	$row->{itemname}	TYPE:$row->{value}\n";
}


dao::saconnect::disconnect( $dbh );

exit (0);
