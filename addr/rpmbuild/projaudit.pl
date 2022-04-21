#!/usr/bin/perl

use strict;

# Audit the files in the project with the files being installed in 
# the .spec file to make sure we're not missing any.

my $projdir = "../";
my $projre = "..\\/";

my @projfiles = `find $projdir -type f | grep -v "CVS" | grep -v "rpmbuild" | grep -v "test" | sed 's/$projre//'`;
my @SPEC = `cat SA-addr.spec`;
my @specfiles = ();

# scrub the input from find 
for (my $i=0; $i<=$#projfiles; $i++) {
	chomp $projfiles[$i];
	$projfiles[$i] =~ s/^$projre.*\///g;
}
 
# extract the files section from the spec file
my $infiles = 0;
for my $line (@SPEC) {
	if ($line =~ /%post/) {
		last;
	}
	if ($line =~ /%files/) {
		$infiles = 1;
	}
	if ($infiles) {
		push( @specfiles, $line );
	}
	
}

# check each projfile and report those that are not yet in the spec
for my $file (@projfiles) {
	my $found = 0;
	foreach (@specfiles) {
		if ($_ =~ /$file/) {
			$found = 1;
			last;
		}
	}
	if (!$found) {
		print "$file\n";
	}
}


exit( 0 );
