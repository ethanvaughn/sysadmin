#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::updateaccount;

use strict;


#----- main ------------------------------------------------------------------
my $username = shift || die "usage: $0 username\n";

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

lib::updateaccount::deleteAccount( $dbh, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::saconnect::disconnect( $dbh );

exit (0);
