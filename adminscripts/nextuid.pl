#!/usr/bin/perl

use strict; 

open( PASSWD, "</etc/passwd" ) or
	die "$!\n";

my $uidhash;
while (<PASSWD>) {
	my @rec = split( /:/ );

	my $uid = $rec[2];	
	if ( $uid > 499 && $uid < 10000 ) {
		$uidhash->{$uid} = $uid;
	}
}

close( PASWD );

# Walk the hash looking for the next available uid
if (! $uidhash) {
	print "500";
}
foreach my $key (sort keys( %$uidhash )) {
	my $nextid = $key + 1;
	if (! exists $uidhash->{ $nextid } ) {
		print $nextid;
		last;
	}
}


exit (0);
