#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::getaccount;

use strict;


my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $res = lib::getaccount::getUsernameList( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: Unable to get user list: $errstr\n";

dao::tmxconnect::disconnect( $dbh );

print "\n";
print "Users:\n";
foreach my $key (keys( %{$res} )) {
	printf "%-20s %-20s\n", $res->{$key}->{'username'}, $res->{$key}->{'gecos'};
}

print "\n";

