package CheckLib;

###################################################################################################################
#
# Purpose:	
#
#		Functions for Nagios libexec "check scripts". 
#
# $Id: CheckLib.pm,v 1.4 2009/07/15 22:03:34 evaughn Exp $
# $Date: 2009/07/15 22:03:34 $
#
###################################################################################################################

use strict;




#----- normalizeServDesc -----------------------------------------------------
# Prepare the Nagios "Service Description" for use in file names, ie. for 
# thresholds files.
sub normalizeServDesc {
	my $servdesc = shift;

	# Strip the end tag:
	$servdesc =~ s/^(.*)\[.*\]/$1/g;

	# Strip trailing whitespace:
	$servdesc =~ s/\s+$//;

	# Replace spaces with underscores:
	$servdesc =~ s/\s/_/g;

	return $servdesc;
}



#----- loadThresholds --------------------------------------------------------
# Load the threshold properties from the thresholds file. 
# Arguments: threshold_file: Full path to the threshold/property file.
#            required: ArrayRef list of required property names.
# Returns:   HashRef keyed on the property name from the file. 
# Note:      The returned hash contains a key called "result" which is used to 
#            transmit "nagios_status:error message". Upon succcess
#            the value will be "0|OK". Otherwise the contents
#            will be an error message.
sub loadThresholds {
	my $threshold_file = shift;
	my $required       = shift;

	my %thresholds;
	$thresholds{result} = "3|Unknown failure.";
		
	my $result = open( FILE, $threshold_file );
	if (!$result) {
		$thresholds{result} = '3|UNKNOWN: Error opening file ' . $threshold_file  . ': ' . $!;
		return \%thresholds;
	}

	# Gather the threshold properties
	while(<FILE>) {
		chomp;
		next if /^#/;
		# Split on the first "=" encountered (hence the "2" in the split args).
		my ($key,$val) = split( /=/, $_, 2 );
		$thresholds{$key} = $val;
	}
	close(FILE);
		
	# Check required fields
	my @missing = ();
	foreach my $field (@$required) {
		if (!defined( $thresholds{$field} )) {
			push( @missing, $field );
		}
	}
	if ($#missing > -1) {
		my $missingstr;
		foreach my $field (@missing) {
			$missingstr .= $field . ',';
		}
		# Snip trailing comma:
		chop( $missingstr );
		$thresholds{result} = '3|Missing required properties from thresholds: ' . $missingstr;
		return \%thresholds;
	}


	$thresholds{result} = "0|OK";
	return \%thresholds;
}


1;
