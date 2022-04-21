#!/usr/bin/perl

use strict;

# Audit the files in the project with the files being installed in 
# the .spec file to make sure we're not missing any.
my $projdir = "../../auth-client tmxaudit-client";
my @projfiles = `find $projdir -type f | grep -v CVS | grep -v test`;
my @SPEC = `cat tmxaudit-client.spec`;
my @specfiles = ();

# scrub the input to include just the file names not the path:
for (my $i=0; $i<=$#projfiles; $i++) {
	chomp $projfiles[$i];
	my @path = split( /\//, $projfiles[$i] );
	#print "DEBUG: projfile=[".$path[$#path]."]\n";
	$projfiles[$i] = $path[$#path];
}
 
# extract the auth-client %files section from the spec file
my $infiles = 0;
for my $line (@SPEC) {
	if ($line =~ /%post/) {
		last;
	}
	if ($line =~ /%files/) { 
		$infiles = 1;
		next;
	}
	if ($line =~ /%defattr/ or $line =~ /^#/) {
		next;
	}
	if ($infiles) {
		# Extract just the filename, not the path
		chomp $line;
		my @path = split( /\//, $line );
		#print "DEBUG: specfile=[".$path[$#path]."]\n";
		if ($path[$#path] eq "") {
			next;
		}
		push( @specfiles, $path[$#path] );
	}
	
}

# check each projfile and report those that are not yet in the spec
for my $file (@projfiles) {
	my $found = 0;
	foreach (@specfiles) {
		#if ($_ =~ /$file/) {
		if ($_ eq $file) {
			$found = 1;
			#print "DEBUG: found $_ = $file\n";
			last;
		}
	}
	if (!$found) {
		print "$file\n";
	}
}


exit( 0 );
