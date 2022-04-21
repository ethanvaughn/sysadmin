#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";

use conf;
use strict;



#----- main ------------------------------------------------------------------
if (! -f "$WORKDIR/passwd.test.l") {
	print "File $WORKDIR/passwd.test.l not found.\n";
	exit( 1 );
}

`cat $WORKDIR/passwd.test.l $WORKDIR/passwd.test.r > $WORKDIR/passwd.test`;
`diff $WORKDIR/passwd.test $WORKDIR/passwd.test.a`;
if ( $? == 0 ) {
	print "[[ TEST SUCCEEDED ]]\n";
} else {
	print "[[ TEST FAILED ]]\n";
}


exit( 0 );
