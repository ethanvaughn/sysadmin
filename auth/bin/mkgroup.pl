#!/usr/bin/perl  -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::getgroup;

use strict;


#----- main ------------------------------------------------------------------
my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $groups = lib::getgroup::mkGroup( $dbh );

foreach my $group (@$groups) {
	print "$group\n";
}

if ($dbh) {
	$dbh->disconnect();
}

exit (0);
