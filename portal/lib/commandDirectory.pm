#!/usr/bin/perl
package lib::commandDirectory;

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use File::Find;
use lib::database;

sub readDirDatabase {
	my @dirs = @_;
	find( \&renameFiles, @dirs );
}

sub delFiles {
	my @dirs = @_;
	find( \&deleteFiles, @dirs );
}

sub delDir {
	my @dirs = @_;
	find( \&deleteDirs, @dirs );
}

sub renameFiles {
	# Only worry about filenames that begin with graph 
	# and are png files
	
	if ( /^graph.*png$/ ) {
		my @images = split ( /_/, $_ );
		
		# Only worry about those expressions that have three array elements
		# such as graph_10_1.png
		
		if ( scalar @images == 3 ) {
			# filename will be as follows: graph_10
			my $filename = $images[0] . "_" . $images[1];
			# images[2] will be as follows 1.png

			my $sql = "SELECT local_graph_id, title FROM cacti.graph_templates_graph WHERE local_graph_id = '$images[1]';";
			my $column = "local_graph_id";
			my $value = lib::database::execSelectQuery( $sql, $column );
			my $newfilename = "$value->{$images[1]}->{title}" . "_" . "$images[2]";
			rename( $_, $newfilename );
		}
	}
}

sub deleteFiles {
	# Delete files within a directory
	unlink or warn "Couldn't remove file: $_\n";
}

sub deleteDirs {
	# Delete an empty directory
	rmdir or warn "Couldn't remove directory: $_\n";
}

1;
