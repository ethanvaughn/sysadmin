#!/usr/bin/perl

use strict;
use CGI;
use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::readGraph;

main();

sub main {
	my $q = new CGI;
	my $site = $q->param( 'dclocation' );
	my $image = $q->param( 'image' );
	my $imgnum = $q->param( 'imgnum' );
	if ( $site eq 'west' ) {
		lib::readGraph::readURL("10.24.74.9","/cacti/graph_image.php?local_graph_id=$image&rra_id=$imgnum");
	} elsif ( $site eq 'south' ) {
		lib::readGraph::readURL("10.24.74.35","/cacti/graph_image.php?local_graph_id=$image&rra_id=$imgnum");
	}
}

