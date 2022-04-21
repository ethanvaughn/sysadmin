#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::hostgroup;

use strict;



#----- Main ------------------------------------------------------------------

# Print a list of all customers:
foreach (lib::hostgroup::listCusts()) {
	print;
	print "\n";
}


exit (0);
