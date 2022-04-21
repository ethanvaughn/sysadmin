package lib::ipfunc;

use Socket;

use FindBin qw( $Bin );
use lib "$Bin/..";


#----- validate_int ----------------------------------------------------------
sub validate_int {
	my $retval = 0;
	if ($_[0] =~ /^\d+$/) {
		$retval = 1;
	}
	return $retval;
}



#----- validate_ip -----------------------------------------------------------
sub validate_ip {
	my $retval = 0;
	if ($_[0] =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
		$retval = 1;
		foreach my $octet ($1,$2,$3,$4) {
			if ($octet > 255 || $octet < 0) {
				$retval = 0;
				last;
			}
		}
	} 
	return $retval;
}



#----- ip2int ----------------------------------------------------------------
# Parameters ($ip)
sub ip2int {
	my $ip = shift;
	
	my $int = undef;
	if (validate_ip( $ip )) {
		$int = unpack( 'N', inet_aton( $ip ) );
	}

	return $int;
}



#----- int2ip ----------------------------------------------------------------
sub int2ip {
	my $int = shift;
	
	my $ip = undef;
	if (validate_int( $int )) {
		$ip = inet_ntoa( pack( "N", $int ) );
	}

	return $ip;
}



#----- int2cidr --------------------------------------------------------------
sub int2cidr {
	my $int = shift;
	
	my $cidr = undef;
	if (validate_int( $int )) {
		my $address_count = 2**32-$int;
		#print "Address Count is $address_count\n";
		for (my $i = 0; $i <= 32; $i++) {
			if (2**$i == $address_count) {
				$cidr = 32-$i;
				last;
			}
		}
	}
	
	return $cidr;
}



#----- cidr2int --------------------------------------------------------------
sub cidr2int {
	my $cidr = shift;
	
	my %cidrtable = (
		16 => 4294901760, # 255.255.0.0
		17 => 4294934528, # 255.255.0.128
		18 => 4294950912, # 255.255.0.192
		19 => 4294959104, # 255.255.0.224
		20 => 4294963200, # 255.255.0.240
		21 => 4294965248, # 255.255.0.248
		22 => 4294966272, # 255.255.0.252
		23 => 4294966784, # 255.255.0.254
		24 => 4294967040, # 255.255.255.0
		25 => 4294967168, # 255.255.255.128
		26 => 4294967232, # 255.255.255.192
		27 => 4294967264, # 255.255.255.224
		28 => 4294967280, # 255.255.255.240
		29 => 4294967288, # 255.255.255.248
		30 => 4294967292, # 255.255.255.252
		31 => 4294967294, # 255.255.255.254
		32 => 4294967295  # 255.255.255.255
	);
	
	return $cidrtable{$cidr};
}



#----- cidr_numhosts --------------------------------------------------------------
# Number of usable hosts on a subnet.
sub cidr_numhosts {
	my $cidr = shift;
	
	my %cidrtable = (
		16 => 65534, # 255.255.0.0
		17 => 32766, # 255.255.128.0
		18 => 16382, # 255.255.192.0
		19 => 8190,  # 255.255.224.0
		20 => 4094,  # 255.255.240.0
		21 => 2046,  # 255.255.248.0
		22 => 1022,  # 255.255.252.0
		23 => 510,   # 255.255.254.0
		24 => 254,   # 255.255.255.0
		25 => 126,   # 255.255.255.128
		26 => 62,    # 255.255.255.192
		27 => 30,    # 255.255.255.224
		28 => 14,    # 255.255.255.240
		29 => 6,     # 255.255.255.248
		30 => 2,     # 255.255.255.252
		31 => 0,     # 255.255.255.254
		32 => 1      # 255.255.255.255
	);
	
	return $cidrtable{$cidr};
}


#----- getIPList -------------------------------------------------------------
# Get a list of IP addresses for the given network (as an integer) and cidr values.
# Returns an arrayref of ip integers.
sub getIPList {
	my $net = shift;
	my $cidr = shift;
	
	my $iplist;
	my $numhosts = cidr_numhosts( $cidr );
	
	for (my $i=0; $i<=($numhosts + 1); $i++) {
		push( @$iplist, $net );
		$net++;
	}
	
	return $iplist;
}



#### Unit Tests
#
#my $ip2int = 0;
#
#if (my $output = (ip2int( '10.24.74.9' )) == 169363977) {
#	print 'ip2int: PASSED: 10.24.74.9 = 169363977',"\n";
#	$ip2int = 1;
#} else {
#	print 'ip2int: FAILED:',$output, '!= 169363977',"\n";
#	$ip2int = 0;
#}
#
#
#if (!ip2int( '256.0.0.0' )) {
#	print 'int2ip: PASSED: 256.0.0.0 invalid',"\n";
#	$int2ip = 1;
#} else {
#	print 'ip2int: FAILED: 256.0.0.0 is NOT valid',"\n";
#	$ip2int = 0;
#}
#
## int2cidr
#my $int2cidr = 0;
#if ($int2cidr) {
#	# Deps met, let's test it
#	my $class_c = ip2int( '255.255.255.0' );
#	if (my $class_c_cidr = ( convert_int_to_cidr($class_c)  ) == 24) {
#		$int2cidr = 1;
#		print 'int2cidr: PASSED: 255.255.255.0 = /24',"\n";
#	} else {
#		print 'int2cidr: FAILED: 255.255.255.0 != ',$class_c_cidr,"\n";
#		$int2cidr = 0;
#	}
#	my $smallest = ip2int( '255.255.255.255' );
#	if (my $smallest_cidr = ( int2cidr($smallest)) == 32) {
#		$int2cidr = 1;
#		print 'int2cidr: PASSED: 255.255.255.255 = /32',"\n";
#	} else {
#		print 'int2cidr: FAILED: 255.255.255.255 != ',$smallest_cidr,"\n";
#		$int2cidr = 0;
#	}
#} else {
#	print 'int2cidr: SKIPPED, dependency FAILED';
#}


1;
