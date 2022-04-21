package utils;

use FindBin qw( $Bin );
use lib "$Bin";


use strict;




#----- Globals ----------------------------------------------------------------
my $prop_file = "/etc/TMXHOST.properties";




#----- get_host_properties ----------------------------------------------------
# Source the properties from the /etc/TMXHOST.properties file.
# Returns a hashref of the properties.
sub get_host_properties {
	my $prop;
	open( PROP, "<$prop_file") ||
		die "Unable to open file [$prop_file] for reading: $!";
	while (<PROP>) {
		my @tmp;
		if ($_ =~ /^.*[=].*/) {
			chomp;
			s/["]//g;
			@tmp = split( /=/ );
			$prop->{$tmp[0]} = $tmp[1];
		}
	}
	close( PROP );
	
	# Verify required properties:
	if (!exists( $prop->{NAGIOS_DATACENTER} )) {
		print STDERR "\n*** Missing NAGIOS_DATACENTER parameter. Check property file: $prop_file\n\n";
		exit 1;
	}
	if (!exists( $prop->{NAGIOS_HOSTNAME} )) {
		print STDERR "\n*** Missing NAGIOS_HOSTNAME parameter. Check property file: $prop_file\n\n";
		exit 1;
	}
	if (!exists( $prop->{NAGIOS_SERVER} )) {
		print STDERR "\n*** Missing NAGIOS_SERVER parameter. Check property file: $prop_file\n\n";
		exit 1;
	}

	return $prop;
}


1;