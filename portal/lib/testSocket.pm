#!/usr/bin/perl -w
#package lib::testSocket;
package lib::portalSocket;

use FindBin qw( $Bin );
use lib "$Bin/..";

use Socket;
use strict;

#----- Main ------------------------------------------------------------------
sub main {
	my $request = shift;
	# initialize host and port
	my @hosts = ( "10.24.74.9", "10.9.15.10" );
	my $port = 80;
	my $proto = getprotobyname('tcp');
	my $wdcstatus = "true"; 
	my $sdcstatus = "true";
	my ( $wdcoutputstatus, $sdcoutputstatus );

	my @list = ();

	# Connect and load the list for each server:
	foreach my $host (@hosts) {
		
		my $paddr = sockaddr_in( $port, inet_aton( $host ) );

		# create the socket, connect to the port
		socket( SOCKET, PF_INET, SOCK_STREAM, $proto ) 
			or die "Unable to open socket to [$host:$port]: $!";
		
		eval {
			local $SIG{ALRM} = sub { die 'Connection timeout' };
			alarm(5);
			connect( SOCKET, $paddr ) or die "Unable to connect to [$host:$port]: $!";
			send( SOCKET, $request, 0 ) or die "Unable to send HTTP Request: $!";
			alarm(0);
		};
		
		if ( $@ ) {
						#die "Eval error's suck bad: $@";
						if ( $host eq "10.24.74.9" ) {
							$wdcstatus = "down";
							$wdcoutputstatus = "false";
						} elsif ( $host eq "10.9.15.10" ) {
							$sdcstatus = "down";
							$sdcoutputstatus = "false";
						}
		} else {

			# Unbuffer the output:
			$| = 1;

			# Get the output and close the socket:
			my @output = <SOCKET>;

			# Check if there is any output from the socket
			close SOCKET or die "Unable to close socket to [$host:$port]: $!";
			if ( $host eq "10.24.74.9" ) {
				if ( $output[3] =~ /Content-Length: 0/ ) {
					$wdcoutputstatus = "false";
				} else {
					$wdcoutputstatus = "true";
					push( @list, @output );
				}
			} elsif ( $host eq "10.9.15.10" ) {
				if ( $output[3] =~ /Content-Length: 0/ ) {
					$sdcoutputstatus = "false";
				} else {
					$sdcoutputstatus = "true";
					push( @list, @output );
				}
			}
		}
	}

	if ( ( $sdcstatus eq "down" ) && ( $wdcstatus eq "down" ) ) {
		print "Refresh: 300\n";
		print "Content-type: text/html\n\n";
		print "<p>Retrieving data from servers...please be patient as data is loaded.</p>";
		print "<p>The page will automatically refresh in 5 minute.</p>";
		exit;
	} else {
		if ( ( $wdcoutputstatus eq "false" ) && ( $sdcoutputstatus eq "false" ) ) {
			# This is to account for the rare situation where both datacenters are up,
			# but no data was received from either monitoring servers.
			print "Refresh: 300\n";
			print "Content-type: text/html\n\n";
			print "<p>Retrieving data from servers...please be patient as data is loaded.</p>";
			print "<p>The page will automatically refresh in 5 minute.</p>";
			exit;
		} else {
			return \@list;
		}
	}
}

1;
