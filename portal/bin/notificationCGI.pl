#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;
use CGI;

$CGI::POST_MAX=1024 * 100; # max 100K posts 
$CGI::DISABLE_UPLOADS = 1; # no uploads

my $directory = $Bin.'/../var';
my $pid = $$;

use lib::execProc;

my $q = new CGI;

main();

sub main {
	# Apache expects a header, so we will give it to Apache
	print 'Content-type: text/plain',"\n\n";
	
	my @passedarguments = $q->param( 'arg' );
	if ( !@passedarguments ) {
		print 'You must specify some arguments',"\n";
	}
	foreach my $argument ( @passedarguments ) {
		my @arguments = split ( /\$/, $argument );
		if ( scalar( @arguments ) == 3 ) {
			my $subject = $arguments[2];
			my $severity = $arguments[1];
			my $customer = $arguments[0];
			#lib::execProc::execProc( 'notifications', [ $subject, $severity, $customer ] );
			my $filename = sprintf('%s/%s.%d-%d',$directory,$customer,$pid,time());
			if (open(FILE,'>'.$filename)) {
				printf(FILE '%d,%s',$severity,$subject);
				close(FILE);
			} else {
				print 'Unable to write to file: ',$!;
			}
		} else {
			print 'Not enough arguments supplied to the CGI script',"\n";
		}
	}
}
