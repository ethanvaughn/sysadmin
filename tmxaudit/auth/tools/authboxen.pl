#!/usr/bin/perl

# Attempt to divine which servers have the auth-client installed.
# We'll do this by comparing the general full list from nquery-listhosts
# to the .tar files in the /u01/home/tmxaudit/clientauth/ directory.
# Hosts in the nquery list that do not have .tar files in the clientauth
# dir most likely have auth-client installed. This is because the 
# client deletes the .tar file each time it processes them.
#
# Yes, this is hokey. It's the quick way until i think of a more
# direct way to implement it.


# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::conf;


use strict;

# ----- Global ---------------------------------------------------------------

my @files = `ls $CLIENTDIR/*.tar`;
# Extract hostname from the file path:
for (my $i=0; $i<=$#files; $i++) {
	chomp $files[$i];
	(my $tmp = $files[$i]) =~ s/$CLIENTDIR\/(.*).tar/$1/;
	$files[$i] = $tmp;
}
# flatten into a single regex-searchable string:
my $filestr = join( " ", @files );

my @hosts = `nq-listhosts.pl`;
# normalize:
for (my $i=0; $i<=$#hosts; $i++) {
	chomp $hosts[$i];
}

# List hosts that are not in files:
foreach my $host (@hosts) {
	print "$host\n" if ($filestr !~ /$host/);
}
