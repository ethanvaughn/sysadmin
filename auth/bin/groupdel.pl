#!/usr/bin/perl 

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::updategroup;

use strict;


#----- main ------------------------------------------------------------------
my $groupname = shift || die "usage: $0 groupname\n";

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

lib::updategroup::deleteGroup( $dbh, $groupname );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::saconnect::disconnect( $dbh );

exit (0);
