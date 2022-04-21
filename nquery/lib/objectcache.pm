package lib::objectcache;

# General functions for parsing records and recordsets from the 
# nagios/var/objects.cache file.


use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::nqcommon;

use strict;


#----- getKeyValue -----------------------------------------------------------
# Parameters: (line)
# For a given line in a define block, return the key and value of the line.
# Returns: array containing [0] key and [1] value.
sub getKeyValue {
	my ($line) = @_;
	# First word is the key, everything else is the value.
	$line =~ s/^\s*(\w+)\s+(\w.*)$/$1:$2/;
	# Kill any trailing whitespace:
	$line =~ s/\s+$//;
	return split( /:/, $line );
}



#----- getRec ----------------------------------------------------------------
# Parameters: ($fh)
# $fh = file handle of the file to parse.
# Returns: a hashref containing this define block's data memebers.
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





#----- getDefineRecs ---------------------------------------------------------
# Parameters: (rectype)
# Get a dataset of all the records in objects.cache of a specified type.
# For example, to get a dataset of the "define hostgroup {" types, "rectype" 
# would be set to "hostgroup".
# Returns: a reference to an array of hashes. Each element in the array 
# contains the hash fields that are present in the objects.cache for that record.
sub getDefineRecs {
	my ($rectype) = @_;

	my @dataset = ();
	my $fhObjectsCache = lib::nqcommon::openFile( "/u01/app/nagios/var/objects.cache" );

	while (<$fhObjectsCache>) {
		if (/^define\s+$rectype\s+\{/) {
			push( @dataset, getRec( $fhObjectsCache ) );
		}
	}
	close( $fhObjectsCache );

	return \@dataset;
}



#----- getHostRecHash ---------------------------------------------------------
# Get a dataset of all the records in objects.cache of type "host".
# Returns: Ref of HoH.
# The hash is keyed by the "host_name" field.
sub getHostRecHash {
	my $fhObjectsCache = lib::nqcommon::openFile( "/u01/app/nagios/var/objects.cache" );
	
	my $dataset;
	
	while (<$fhObjectsCache>) {
		if (/^define\s+host\s+\{/) {
			my $rec = getRec( $fhObjectsCache );
			$dataset->{$rec->{host_name}} = $rec;
		}
	}
	close( $fhObjectsCache );

	return $dataset;
}



#----- getHostgroupRecHash ---------------------------------------------------------
# Get a dataset of all the records in objects.cache of type "hostgroup".
# Returns: Ref of HoH.
# The hash is keyed by the "host_name" field.
sub getHostgroupRecHash {
	my $fhObjectsCache = lib::nqcommon::openFile( "/u01/app/nagios/var/objects.cache" );
	
	my $dataset;
	
	while (<$fhObjectsCache>) {
		if (/^define\s+hostgroup\s+\{/) {
			my $rec = getRec( $fhObjectsCache );
			$dataset->{$rec->{hostgroup_name}} = $rec;
		}
	}
	close( $fhObjectsCache );

	return $dataset;
}



#----- getServiceRecHash ---------------------------------------------------------
# Get a dataset of all the records in objects.cache of type "service".
# Returns: Ref of HoH.
# The hash is keyed by the "host_name" field.
sub getServiceRecHash {
	my $fhObjectsCache = lib::nqcommon::openFile( "/u01/app/nagios/var/objects.cache" );
	my $hostgrouplist = getHostgroupRecHash();
	
	my $dataset;
	
	while (<$fhObjectsCache>) {
		if (/^define\s+service\s+\{/) {
			my $rec = getRec( $fhObjectsCache );
			my @hosts;
			my $key;
			if ($rec->{host_name}) {
				push( @hosts, $rec->{host_name} );
			}
			if ($rec->{hostgroup_name}) {
				# Build a list of host_names for this hostgroup:
				my $hg = $hostgrouplist->{$rec->{hostgroup_name}};
				# Since host_name and hostgroup_name can exist in the same
				# service, we need to append without overwriting ...
				foreach my $host (split( /,/, $rec->{members} )) {
					push( @hosts, $host );
				}
			}
			# Build a compound key.
			foreach my $host (@hosts) {
				$key = $host . "|" . $rec->{service_description};	
			}
			
			$dataset->{$key} = $rec;
		}
	}
	close( $fhObjectsCache );

	return $dataset;
}



#----- getServDescList ---------------------------------------------------------
# Get a simple sorted list of all service_descr on this box.
# Returns: array
sub getServDescList {
	my $fhObjectsCache = lib::nqcommon::openFile( "/u01/app/nagios/var/objects.cache" );
	
	my %serv_uniq;
	my @unsorted;
	my @sorted;
	
	while (<$fhObjectsCache>) {
		if (/^define\s+service\s+\{/) {
			my $rec = getRec( $fhObjectsCache );
			$serv_uniq{$rec->{service_description}} = "";
		}
	}
	close( $fhObjectsCache );

	foreach my $key (keys( %serv_uniq )) {
		push( @unsorted, $key );
	}
	
	@sorted = sort( @unsorted );
	
	return \@sorted;
}


1;
