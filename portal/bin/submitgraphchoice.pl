#!/usr/bin/perl

use strict;
use CGI;
use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::readGraph;
use lib::createHTML;

# Global CGI variable
my $q = new CGI();

# Global variable for all form input (selectbox choices)
my %input;

my $portal_username = $q->cookie( 'tomaxportalusername' );
my $nagios_username = $q->cookie( 'tomaxportalcustomer' );
my $upperusername = "\U$nagios_username";

init();
main();

sub init {
	for my $key ( $q->param() ) {
		$input{$key} = $q->param($key);
	}
}

sub main {
	my @dataset;
	my ( $location, $image, $imgnum );
	while ( my ( $key, $value ) = each %input ) {
		if ( $value ne "" and $value !~ /Submit/ ) {
			my @image_number_array;
			my %temphash;
			if ( $key =~ /graph/ ) {
				@image_number_array = split( "_", $value );
				$location = $image_number_array[0];
				$image = $image_number_array[1];
				$imgnum = $image_number_array[2];
				if ( $imgnum == 1 ) {
					$temphash{timeperiod} = "Daily";
				} elsif ( $imgnum == 2 ) {
					$temphash{timeperiod} = "Weekly";
				} elsif ( $imgnum == 3 ) {
					$temphash{timeperiod} = "Monthly";
				} elsif ( $imgnum == 4 ) {
					$temphash{timeperiod} = "Yearly";
				}
				$temphash{location} = $location;
				if ( $location eq "west" ) {
					$temphash{location} = $location;
				} else {
					$temphash{location} = undef;
				}
				$temphash{image} = $image;
				$temphash{imgnum} = $imgnum;
			}
			push( @dataset, \%temphash );
		}
	}
	lib::createHTML::newTemplate( 'printviewgraphs', 'Print View Graphs', [ $q, \@dataset, $portal_username ] );
}
