#!/usr/bin/perl
package lib::createHTML;

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;
use HTML::Template;
	
my $template;

sub newTemplate {
  my ( $filename, $title, $args ) = @_;
  # Check to make sure we actually got a filename
  my $basedir = '/u01/app/portal/html';
  $template = HTML::Template->new( filename => $basedir.'/'.$filename.'.html', die_on_bad_params => 0, loop_context_vars => 1, global_vars => 1 );
  $template->param( cgi => @$args[0]->url( -absolute => 1 ) ); # CGI Script Name
  $template->param( title => $title );
	$template->param( dataset => @$args[1] );
	if ( @$args[2] ) {
		$template->param( desc => @$args[2] );
	}
	if ( @$args[3] ) {
		$template->param( address => @$args[3] );
	}
	if ( @$args[4] ) {
		$template->param( portalusername => @$args[4] );
	}
	if ( @$args[5] ) {
		$template->param( host => @$args[5] );
	}
	if ( @$args[6] ) {
		$template->param( site => @$args[6] );
	}
	makeHTML();
}

sub makeHTML {
		print "Refresh: 60\n";
    print "Cache-Control: private-must-revalidate\n";
    print "Content-type: text/html\n\n";
    print $template->output();
    exit 0;
}

1;
