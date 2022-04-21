#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";

use Sys::Syslog;

use ac;
use conf;

use strict;


#----- Globals ---------------------------------------------------------------
my @remotefiles = (
	"work/passwd.r",
	"work/shadow.r",
	"work/group.r"
);



#----- main ------------------------------------------------------------------
# Create and delete home dirs as appropriate:
ac::setDefaultPolicies( \@remotefiles );


exit (0);
