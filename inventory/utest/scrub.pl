#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::vo;

use strict;


# Build the hashref to simulate user input:
my %tmphash = (
	val1 => "Static Test",
	val2 => "^+S\'C;R.{<U>B}:, |T/E\\S`~\$\*T?\"",
	val3 => "\@#-_()\%!Valid Chars"
);
my $vars = \%tmphash;

$vars = lib::vo::scrub( $vars );

my $T1 = "Static Test";
print "TEST 1: [$T1]=[$vars->{val1}] ..................... ";
if ($T1 eq $vars->{val1}) {
	print "[ SUCCESS ]\n";
} else {
	print "[ FAILURE ]\n";
}


my $T2 = "SCRUB TEST";
print "TEST 2: [$T2]=[$vars->{val2}] ....................... ";
if ($T2 eq $vars->{val2}) {
	print "[ SUCCESS ]\n";
} else {
	print "[ FAILURE ]\n";
}


my $T3 = "\@#-_()\%!Valid Chars";
print "TEST 3: [$T3]=[$vars->{val3}] ..... ";
if ($T3 eq $vars->{val3}) {
	print "[ SUCCESS ]\n";
} else {
	print "[ FAILURE ]\n";
}


exit (0);
