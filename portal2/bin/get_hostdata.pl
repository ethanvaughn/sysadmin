#!/usr/bin/perl -w

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;

use JSON;
use LWP;

use lib::conf;


#---- Globals / Constants -----------------------------------------------------
my %URLS = ( wdc => 'nquery/wdc', sdc => 'nquery/sdc' );
my $EXCLUDE = 'infra|lom|netapp|demo|mgmt|tunnel';
my $ua = LWP::UserAgent->new();
$ua->timeout( 30 );




#---- Main -------------------------------------------------------------------
# Get list of customers and the datacenter they belong to.
# The hash is of the form $custs{cust_code} = "dc" (eg. $custs{rat} = "wdc").
my %custs;
foreach my $dc (keys( %URLS )) {
	my $proxy_url = $URLS{ $dc };
	my $url = "listcusts";
	my $response = $ua->get( "http://$PROXY_IP/$proxy_url/$url" );
	if (!$response->is_success) {
		print "Unable to query customer list for datacenter $dc\n";
		print "    " . $response->status_line . "\n";
		next;
	}
	my @lines = split( /\r\n|\n/, ${$response->content_ref} );
	foreach my $line (@lines) {
		if ($line !~ /$EXCLUDE/) {
			$custs{$line} = $dc;
		}
	}
}

# Create a hash of status information for all hosts; hostname as the key
my %statuslist;
foreach my $dc (keys( %URLS )) {
	my $proxy_url = $URLS{ $dc };
	my $url = "liststatcsv";
	my $response = $ua->get( "http://$PROXY_IP/$proxy_url/$url" );
	if (!$response->is_success) {
		print "Unable to query nagios status list for datacenter $dc\n";
		print "    " . $response->status_line . "\n";
		next;
	}
	my @lines = split( /\r\n|\n/, ${$response->content_ref} );
	foreach my $line (@lines) {
		my @fields = split( /[|]/, $line );

		my $rec = {
			hostname                      => $fields[0],
			service_description           => $fields[1],
			plugin_output                 => $fields[2],
			problem_has_been_acknowledged => $fields[3],
			scheduled_downtime_depth      => $fields[4],
			current_state                 => $fields[5]
		};
		
		if (!exists( $statuslist{$fields[0]} )) {
			# Initialize the array
			$statuslist{$fields[0]} = [];
		}
		push( @{$statuslist{$fields[0]}}, $rec );
	}
}


# DEBUG
#foreach my $hostname (keys( %statuslist )) {
#	print "$hostname | $statuslist{$hostname}->[0]->{service_description}\n";
#	print "$hostname | $statuslist{$hostname}->[1]->{service_description}\n";
#	print "\n";
#}
#print "\n";
#exit 1;

# Process the hostdata for each customer.
foreach my $cust (keys( %custs )) {
	print "\nProcessing cust [$cust] at datacenter [$custs{$cust}] ... \n";

	# Assign $proxy_url based on datacenter of the customer. The $proxy_url 
	# is the base URL on the reverse proxy server.
	my $dc = $custs{$cust};
	my $proxy_url = $URLS{ $dc };
	# The $url is the real URL to be queried through the proxy.
	my $url = "listhosts?info=1&cust=$cust";

	my $response = $ua->get( "http://$PROXY_IP/$proxy_url/$url" );
	if (!$response->is_success) {
		print "Unable to query host data for customer $cust\n";
		print "    " . $response->status_line . "\n";
		next;
	}


	# Parse the comma-del host information.
	my %dataset;
	my @lines = split( /\r\n|\n/, ${$response->content_ref} );
	foreach my $line (@lines) {
		my %hosthash;
		my @hostinfo = split( /,/, $line );

		$hosthash{hostname}         = $hostinfo[0];
		$hosthash{ip_address}       = $hostinfo[1];
		$hosthash{description}      = $hostinfo[2];
		$hosthash{host_status}      = $hostinfo[3];
		$hosthash{service_status}   = $hostinfo[4];
		$hosthash{host_ack}         = $hostinfo[5];
		$hosthash{serv_ack}         = $hostinfo[6];
		$hosthash{host_maintenance}	= $hostinfo[7];
		$hosthash{serv_maintenance} = $hostinfo[8];

		$hosthash{status_detail}     = $statuslist{$hosthash{hostname}};

		$dataset{$hosthash{hostname}} = \%hosthash;
	}


	# Write this customer's host data.
	my $datafile = $DATAPATH . "/hostdata/$cust-hostdata.json";
	if (!open( HOSTDATA, ">$datafile" )) {
		print 'Unable to open file [' . $datafile . '] for writing: ' . "$!\n";
		next;
	}
	print HOSTDATA to_json( \%dataset );
	close( HOSTDATA );
}




exit (0);
