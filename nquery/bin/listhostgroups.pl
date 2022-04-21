#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::hostgroup;

use strict;



#----- Main ------------------------------------------------------------------

my $hostgrouplist = lib::objectcache::getHostgroupRecHash();

foreach my $key (keys( %$hostgrouplist )) {
	print "\n[$key]\n";
	my @members = split( /,/, $hostgrouplist->{$key}{members} );
	foreach my $host (@members) {
		print "    $host\n";
	}
}


exit (0);
