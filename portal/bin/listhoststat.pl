#!/usr/bin/perl

use strict;
use FindBin qw( $Bin );
use lib "$Bin/..";
use lib::URLQuery;
use lib::createHTML;
use lib::auth;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use MLDBM qw(DB_File);
use Fcntl;

my $q = new CGI;
my $portal_username = $q->cookie( 'tomaxportalusername' );
my $nagios_username = $q->cookie( 'tomaxportalcustomer' );
my $upperusername = "\U$nagios_username";
my $host = $q->param( 'host' );
my $site;


# Get the cookie values
my ($username, $password, $cust) = lib::auth::getCookieValues( $q );


#----- main --------------------------------------------------------------
# Authenticate or die.
if (!lib::auth::isValidUser( $username, $password )) {
	print 'Location: ../login.html',"\n\n";
	exit 0;
}
	

my $dataset = builddata();
my $description = $q->param( 'description' );
my $address = $q->param( 'address' );
lib::createHTML::newTemplate( 'listhostservice2', 'Service Status', [ $q, $dataset, $description, $address, $portal_username, $host, $site ] );


sub builddata {
	my $url = sprintf('listhoststat?host=%s',$host);
	my $raw_data = lib::URLQuery::fetchURL($url);
	my @lines = split(/\r\n|\n/,$$raw_data);
	my $data = \@lines; # Create an array ref of the same so as not to break all of the craptastic code below

	my @arrayofhashes;

	my $size = scalar(@$data);

	for ( my $index = 0; $index < $size; $index++ ) {
		my %servicehash;
	  if ( @$data[$index] =~ /service \{$/ ) {
			while ( $index < $size ) {
				chomp( @$data[$index] );
				if ( @$data[$index] =~ /\}/ ) {
					last;
				}
				if ( @$data[$index] =~ /problem_has_been_acknowledged/ ) {
					$servicehash{'serv_ack'} = getValue( @$data[$index], 'problem_has_been_acknowledged=' );
				}
				if ( @$data[$index] =~ /plugin_output/ ) {
					$servicehash{'plugin_output'} = getValue( @$data[$index], 'plugin_output=' );
				}
				if ( @$data[$index] =~ /service_description/ ) {
					my $serv = getValue( @$data[$index], 'service_description=' );
					$servicehash{'description'} = getValue( @$data[$index], 'service_description=' );
					$servicehash{'image'} = isImage( $servicehash{'description'} );
				}
				if ( @$data[$index] =~ /scheduled_downtime_depth/ ) {
					$servicehash{'maintenance'} = getValue( @$data[$index], 'scheduled_downtime_depth=' );
				}
				if ( @$data[$index] =~ /current_state/ ) {
					$servicehash{'current_state'} = getValue( @$data[$index], 'current_state=' );
					if ( $servicehash{'current_state'} eq "0" ) {
						$servicehash{'service_up'} = 1;
					} elsif ( $servicehash{'current_state'} eq "1" ) {
						$servicehash{'service_warning'} = 1;
					} elsif ( $servicehash{'current_state'} eq "2" || $servicehash{'current_state'} eq "3" ) {
						$servicehash{'service_critical'} = 1;
					}
				}
				$index++;
			} 
			push ( @arrayofhashes, \%servicehash );
		} 
	} 
	return \@arrayofhashes;
}

sub getValue {
  my ($input, $match) = @_;   
	$input =~s/^.*$match//;
  return $input;
}

sub isImage {
	# There's only one site now, which isn't SDC but because of the way this awful mess
	# is coded, appears to be.  So accept that the graph file is the SDC one and move on
	my $service = shift;
	#my $graphtreefilewest = "/u01/app/portal/lib/graphtreewest";
	my $graphtreefilesouth = "/u01/app/portal/lib/graphtreesouth";
	my ( %graphtreewest, %graphtreesouth );
	my $imagenumber = 0;
	#tie( %graphtreewest, "MLDBM", $graphtreefilewest, O_RDONLY, 0666, ) || die "Cannot open $graphtreefilewest\n";
	tie( %graphtreesouth, "MLDBM", $graphtreefilesouth, O_RDONLY, 0666, ) || die "Cannot open $graphtreefilesouth\n";
	#foreach my $graph ( @{$graphtreewest{$upperusername}->{'hosts'}{$host}} ) {
	#	if ( $graph->{'service'} eq $service ) { 
	#		$imagenumber = $graph->{'gid'};
	#		$site = "west";
	#	}
	#}
	foreach my $graph ( @{$graphtreesouth{$upperusername}->{'hosts'}{$host}} ) {
		if ( $graph->{'service'} eq $service ) { 
			$imagenumber = $graph->{'gid'};
			$site = "south";
		}
	}
	#untie( %graphtreewest, %graphtreesouth );
	untie( %graphtreesouth );
	return ( $imagenumber );
}
