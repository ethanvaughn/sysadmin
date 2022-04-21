#!/usr/bin/perl

use Net::FTP;

use ac;

use strict;

#----- Main ------------------------------------------------------------------

my $hostname = "authfilesFOO";
my $ipaddr = "11.22.33.44";
my $msg = ac::getBundle( 1, [ $hostname, $ipaddr ] );

print "$msg\n";

exit 0;
