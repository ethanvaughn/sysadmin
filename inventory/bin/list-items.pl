#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
#use dao::item;
use lib::item;
#use lib::company;
#use lib::property;

use strict;


#----- Main ------------------------------------------------------------------

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


my $item_list = lib::item::getItemList( $dbh );
foreach my $itemname (sort keys( %$item_list )) {
	print "\n[  $itemname  ]\n";
	my $rec = $item_list->{$itemname};
	foreach my $key (keys( %$rec )){
		print "    $key = $rec->{$key}\n";
	}
}

dao::saconnect::disconnect( $dbh );

exit (0);
