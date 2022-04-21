#!/usr/bin/perl -w


# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::utest;
use lib::conf;

use strict;


#----- main ------------------------------------------------------------------
my $dp = $CLIENTDIR;
my $projpath = "$Bin/..";

# Create the unit test files for client-side algorithm validation.
lib::utest::mkTestFiles( $dp );

# Create the authentication files for the remote managed accounts:
`$Bin/mkpasswd.pl > $dp/passwd.r`;
`$Bin/mkshadow.pl > $dp/shadow.r`;
`$Bin/mkgroup.pl > $dp/group.r`;

# Add root to the authentication files for stand-alone recovery:
`cp $projpath/recovery/R* $dp`;
`cat $dp/passwd.r >> $dp/Rpasswd`;
`cat $dp/shadow.r >> $dp/Rshadow`;
`cat $dp/group.r >> $dp/Rgroup`;

exit (0);
