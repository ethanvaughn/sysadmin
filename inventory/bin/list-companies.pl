#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::company;

use strict;


#----- Main ------------------------------------------------------------------

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


my $data = lib::company::getCompanyList( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Database error getCompanyList: $errstr\n";

foreach my $row (@$data) {
	printf "%10.10s   %s\n", $row->{code}, $row->{name};
}


dao::saconnect::disconnect( $dbh );

exit (0);
