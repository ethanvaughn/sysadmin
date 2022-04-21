#!/usr/bin/perl -w


# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::getaccount;

use strict;


#----- main ------------------------------------------------------------------
my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $acctref = lib::getaccount::getAccounts( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::tmxconnect::disconnect( $dbh );

foreach my $key (keys( %{$acctref} )) {
	print "$acctref->{$key}->{'username'}:x:$acctref->{$key}->{'uid'}:$acctref->{$key}->{'gid'}:$acctref->{$key}->{'gecos'}:$acctref->{$key}->{'homedir'}:$acctref->{$key}->{'shell'}\n";
}

exit (0);
