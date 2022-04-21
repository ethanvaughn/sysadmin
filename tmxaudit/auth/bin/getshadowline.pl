#!/usr/bin/perl -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use lib::passwdutils;

print "\nExample shadow line for today:\n";
my $lastchange = lib::passwdutils::getLastchange10();
print "username:passwd:$lastchange:0:3650:7:::\n\n";

exit( 0 );
