#!/usr/bin/perl

use strict;
use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::buildtree;

#lib::buildtree::buildgraphtreewest();
# There is only one graphing server now (05/13/08)
# But due to the way the crappy logic works in this program,
# we just comment out the graphtreewest function and
# let it only poll the 'south' grapph server, which is
# actually the main (and only) graph server used
lib::buildtree::buildgraphtreesouth();
