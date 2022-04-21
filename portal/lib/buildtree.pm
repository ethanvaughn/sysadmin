#!/usr/bin/perl

package lib::buildtree;
use strict;
use MLDBM qw(DB_File);
use Fcntl;
use DBI;
use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::execSQL;
use lib::tree;

sub buildgraphtreewest {
	my $hostname = "10.24.74.9";
	my @tree; # The graph tree
	my $dbh; # DB Connect object
	my $graphtreefilewest = "/u01/app/portal/lib/graphtreewest";
	lib::execSQL::connectDB( $hostname );

	my $t1 = lib::execSQL::execSQL('select name,id from cacti.graph_tree');
	my %graphtree;
	tie( %graphtree, "MLDBM", $graphtreefilewest, O_RDWR|O_CREAT, 0666, ) || die "Cannot create file\n";
	foreach my $tree (@$t1) {
		my $returngraphtree = lib::tree::buildTree($tree);
		$graphtree{$tree->{name}} = $returngraphtree;
	}
	lib::execSQL::disconnectDB();
	untie( %graphtree );
}

sub buildgraphtreesouth {
	my $hostname = "10.24.74.35";
	my @tree; # The graph tree
	my $dbh; # DB Connect object
	my $graphtreefilesouth = "/u01/app/portal/lib/graphtreesouth";
	lib::execSQL::connectDB( $hostname );

	my $t1 = lib::execSQL::execSQL('select name,id from cacti.graph_tree');
	my %graphtree;
	tie( %graphtree, "MLDBM", $graphtreefilesouth, O_RDWR|O_CREAT, 0666, ) || die "Cannot create file\n";
	foreach my $tree (@$t1) {
		my $returngraphtree = lib::tree::buildTree($tree);
		$graphtree{$tree->{name}} = $returngraphtree;
	}
	lib::execSQL::disconnectDB();
	untie( %graphtree );
}

1;
