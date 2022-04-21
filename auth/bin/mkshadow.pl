#!/usr/bin/perl -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::getaccount;

use strict;


#----- main ------------------------------------------------------------------
my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $accounts = lib::getaccount::mkShadow( $dbh );

foreach my $account (@$accounts) {
	print "$account\n";
}

if ($dbh) {
	$dbh->disconnect();
}

exit (0);
