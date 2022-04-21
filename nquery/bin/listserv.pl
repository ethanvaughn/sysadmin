#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::objectcache;

use strict;



#----- Main ------------------------------------------------------------------

my $servlist = lib::objectcache::getServiceRecHash();

foreach my $key (keys( %$servlist )) {
#	print "$key=" . $servlist->{$key}{service_description} . "\n";
	print "$key\n";
}


exit (0);
