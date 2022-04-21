#!/usr/bin/perl

use strict;
use HostToGroup;

my $cfg = '/u01/app/nagios/etc/hostgroups.cfg';
my $out = mapHostToGroup($ARGV[0],$cfg);

if (isGroup('atg',$cfg)) {
	print "atg is a group\n";
} else {
	print "atg is NOT a group\n"; # BAD!!
}

if (isGroup('foo',$cfg)) {
	print "foo is a group\n"; # Bad, shouldn't happen
} else {
	print "foo is not a group\n"; # good, should happen
}

print "Group: $out\n";
