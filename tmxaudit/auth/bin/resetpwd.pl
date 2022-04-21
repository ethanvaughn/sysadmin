#!/usr/bin/perl -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use dao::tmxconnect;
use lib::updateaccount;

my $username = shift || die "usage: $0 username\n";

my $dbh = dao::tmxconnect::connect();

lib::updateaccount::resetpwd( $dbh, $username );

dao::tmxconnect::disconnect( $dbh );

`$Bin/send-reset-email.pl $username`;

# Update auth files for all hosts:
`$Bin/mkclientdata.pl`;

exit( 0 );
