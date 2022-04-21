#!/usr/bin/perl -w


# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::conf;

use strict;


#----- main ------------------------------------------------------------------
my $client = shift || die "usage: $0 hostname\n";
my $dp = $CLIENTDIR;

`$Bin/mkauthfiles.pl`;

# Create the client tarball:
`tar -C $dp -cf /$dp/$client.tar passwd.r shadow.r group.r Rpasswd Rshadow Rgroup passwd.test.l shadow.test.l group.test.l passwd.test.r shadow.test.r group.test.r passwd.test.a shadow.test.a group.test.a`;

exit (0);
