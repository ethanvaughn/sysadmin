#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::sendcmd;

use strict;


lib::sendcmd::sendcmd( "evaughn", "nji90okm", "uname -a;cat /etc/issue", "10.24.81.30" );

