#!/usr/bin/perl -w


# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::clientinfo;
use lib::conf;

use strict;


#----- main ------------------------------------------------------------------
# Clean and prep the download directory:
`/bin/rm -rf $CLIENTDIR/*`;

# Create the auth files from the DB:
`$Bin/mkauthfiles.pl`;

# Get a list of currently active hosts:
my @hosts = lib::clientinfo::listHosts();
# Add the vmclient to the hostlist for testing:
push( @hosts, "vmclient" );

# Create the model tar file
`/bin/tar -C $CLIENTDIR -cf $CLIENTDIR/authfiles.tar passwd.r shadow.r group.r`;

# Create the server-specific files as hard-links:
for my $client (@hosts) {
	chomp $client;
	`/bin/ln -f $CLIENTDIR/authfiles.tar $CLIENTDIR/$client.tar`;
}

# Finalize and set permissions:
`/bin/chmod 666 $CLIENTDIR/*`;
`/bin/chmod 666 $CLIENTDIR/*`;


exit (0);
