#!/usr/bin/perl  -w

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::tmxconnect;
use lib::getgroup;

use strict;


#----- main ------------------------------------------------------------------
my $dbh = dao::tmxconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my %groupdata = lib::getgroup::getGroupData( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";


$dbh->disconnect();


for my $groupname (keys(%groupdata)){
	print $groupname . ":x:"; 
	# Index 0 is the gid.
	print $groupdata{$groupname}->[0] . ":";
	# Loop through the usernames.
	my $count = $#{$groupdata{$groupname}};
	for (my $i=1; $i<=$count; $i++) {
		print "$groupdata{$groupname}->[$i]";
		if ($i != $count) {
			print ",";
		}
	}
	print "\n";
}


exit (0);
