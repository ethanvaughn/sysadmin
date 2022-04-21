#!/usr/bin/perl -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use dao::saconnect;
use lib::updateaccount;

my $username = shift || die "usage: $0 username\n";

my $dbh = dao::saconnect::connect();

lib::updateaccount::resetpwd( $dbh, $username );

dao::saconnect::disconnect( $dbh );

`$Bin/send-reset-email.pl $username`;

exit( 0 );
