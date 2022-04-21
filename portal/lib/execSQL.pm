#!/usr/bin/perl
#
#execSQL package
package lib::execSQL;

use FindBin qw( $Bin );
use lib "$Bin/..";

my $dbh;

sub execSQL {
	my $query = shift;
	die "No query found" if !$query;
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my @results;
	while (my $href = $sth->fetchrow_hashref()) {
		push(@results, $href);
	}
	if (@results) {
		return \@results;
	} else {
		return undef;
	}
}
sub disconnectDB {
	$dbh->disconnect() if $dbh;
}

sub connectDB {
	my $hostname = shift;
	my $database = "cacti";
	my $port = "3306";
	my $user = "portal";
	my $pass = 'p0rt@l';
	my $dsn = "DBI:mysql:database=$database;host=$hostname;port=$port";
	$dbh = DBI->connect($dsn, $user, $pass) or die "Cannot connect to database $DBI::errstr";
}

1;
