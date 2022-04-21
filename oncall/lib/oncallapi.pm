package lib::oncallapi;

use strict;
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::oncall_mysqlconnect;

# This is the 'constructor' of sorts for this lib module: instantiate the object and tell it to connect
my $obj = new dao::oncall_mysqlconnect;
$obj->connect() || die $obj->dberr;

# Ancilliary Methods
# These methods track status and report back errors

sub isConnected {
	return $obj->{connected};
}

sub dberr {
	return $obj->{dberr};
}

# Data-retrieval mathods

sub getGroupMemberPhone {
	return $obj->getGroupMemberPhone();
}

sub getGroupMemberEmailAndPager {
	return $obj->getGroupMemberEmailAndPager();
}

