#!/usr/bin/perl -w

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use JSON;

use lib::conf;
use lib::notifications;

#---- Globals / Constants -----------------------------------------------------




#---- Main -------------------------------------------------------------------
my $notifications = lib::notifications::readEvents( "rat" );

print to_json( $notifications );

exit (0);
