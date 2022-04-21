#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::getaccount;

use strict;


#----- main ------------------------------------------------------------------
my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $acctref = lib::getaccount::getShadowAttr( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::tmxconnect::disconnect( $dbh );

foreach my $key (keys( %{$acctref} )) {
	print "$acctref->{$key}->{'username'}:$acctref->{$key}->{'md5_passwd'}:$acctref->{$key}->{'sh_lastchange'}:$acctref->{$key}->{'sh_min'}:$acctref->{$key}->{'sh_max'}:$acctref->{$key}->{'sh_warn'}:$acctref->{$key}->{'sh_inact'}:$acctref->{$key}->{'sh_expire'}:\n";
}

exit (0);
