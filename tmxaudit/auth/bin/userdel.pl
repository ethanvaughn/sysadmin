#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::updateaccount;

use strict;


#----- main ------------------------------------------------------------------
my $username = shift || die "usage: $0 username\n";

my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

lib::updateaccount::deleteAccount( $dbh, $username );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::tmxconnect::disconnect( $dbh );

# Update auth files for all hosts:
`$Bin/mkclientdata.pl`;

exit (0);
