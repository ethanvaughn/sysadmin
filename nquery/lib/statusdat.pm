package lib::statusdat;

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::nqcommon;
use lib::hostgroup;

use strict;


#----- getKeyValue -----------------------------------------------------------
# Parameters: (line)
# Split key/value For a given line in a record block.
# Returns: array containing [0] key and [1] value.
sub getKeyValue {
	my ($line) = @_;

	# Kill any leading/trailing whitespace:
	$line =~ s/^\s+?//;
	$line =~ s/\s+$//;
	# All chars before first '=' is the key, everything else is the value.
	$line =~ s/^(.*?)[=](.*)$/$1|$2/;
	return split( /\|/, $line );
}



#----- getRec ----------------------------------------------------------------
# Parameters: ($fh)
# $fh = file handle of the file to parse.
# Returns: a hashref containing this record  block's data memebers.
sub getRec {
	my ($fh) = @_;
	
	my %rec;

	while (<$fh>) {
		chomp;
		if (/}/) {
			last;
		}
		my @keyval = getKeyValue( $_ );
	
		$rec{$keyval[0]} = $keyval[1];
	}
	return \%rec;
}


#----- getStatus ----------------------------------------------------------------
# Parameters ()
# Returns array of all records from the status.dat as hashes. 
sub getStatus {
	my $hostname = shift;

	my @dataset = ();
	my $fh = lib::nqcommon::openFile( "/u01/app/nagios/var/status.dat" );

	my %tmphash;
	while (<$fh>) {
		if (/{/) {
			my $firstline = $_;
			chomp $firstline;
			# strip leading whitespace:
			$firstline =~ s/^\s+?//;
			push( @dataset, getRec( $fh ) );
			@dataset[$#dataset]->{'firstline'} = $firstline;
			@dataset[$#dataset]->{'lastline'} = "}";
		}
	}
	close( $fh );

	return @dataset;
}



#----- getStatusByHost ----------------------------------------------------------------
# Parameters ( hostname )
# Returns array of hash records from the status.dat for the specified host. 
sub getStatusByHost {
	my $hostname = shift;

	my @allrecs = getStatus();
	my @hostrecs = ();

	foreach my $rec (@allrecs) {
		if ( $rec->{'host_name'} eq $hostname ) {
			push( @hostrecs, $rec );
		}
	}

	return @hostrecs;
}



#----- getStatusByCust ----------------------------------------------------------------
# Parameters ( custcode )
# Returns array of hash records from the status.dat for the specified nagios custcode. 
sub getStatusByCust {
	my $cust = shift;

	my %criteria = ( cust => $cust );
	my @hostlist = lib::hostgroup::listHosts( \%criteria );

	my @allrecs = getStatus();
	my @custrecs = ();

	# Flatten hostlist into a single line for regex comparisions:
	my $sHosts = "";
	foreach my $hostname (@hostlist) {
		$sHosts .= $hostname . " ";
	}

	# Gather all 'host' and 'service' recs for this host:
	foreach my $rec (@allrecs) {
		if ( $sHosts =~ $rec->{host_name} ) {
			push( @custrecs, $rec );
		}
	}


	return @custrecs;
}



#----- getUnack ----------------------------------------------------------------
# Parameters ( )
# Returns array of hash records from the status.dat that are open and 
# unacknowledged. 
sub getUnack {

	my @allrecs = getStatus();
	my @unackrecs = ();
	

	foreach my $rec (@allrecs) {
		# Gather the unack'd records:
		# These two cases should cover all hosts and services that need to be ack'd.
		if ( $rec->{'current_notification_number'} > 0 
		and $rec->{'problem_has_been_acknowledged'} == 0
		) {
			push( @unackrecs, $rec );
		}
	}

	return @unackrecs;
}

1;
