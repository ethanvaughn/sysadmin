package lib::clientinfo;
# Fnctions relating to gathering information about the hosts that are managed
# by this authentication system.

use FindBin qw( $Bin );
use lib "$Bin/..";

use strict;


#----- listHosts -----------------------------------------------------------
# Parameters ()
# Returns array list of managed hostnames.
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listHosts { 
	return `/usr/bin/nq-listhosts.pl`;
}



#----- listHostsForCust -----------------------------------------------------------
# Parameters ($custcode)
# Returns array list of managed hostnames.
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listHostsForCust { 
	my $custcode = shift;

	return `/usr/bin/nq-listhosts.pl -c $custcode`;
}


#----- listLabHosts -----------------------------------------------------------
# Parameters ()
# Returns array list of managed hostnames that are lab, dev, train (ie. non-production)..
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listLabHosts { 
	return `/usr/bin/nq-listhosts.pl -e "lab"`;
}


#----- listLabHostsForCust -----------------------------------------------------------
# Parameters ($custcode)
# Returns array list of managed hostnames.
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listLabHostsForCust { 
	my $custcode = shift;

	return `/usr/bin/nq-listhosts.pl -c $custcode -e "lab"`;
}



#----- listProdHosts -----------------------------------------------------------
# Parameters ()
# Returns array list of managed hostnames.
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listProdHosts { 
	return `/usr/bin/nq-listhosts.pl -e "prod"`;
}


#----- listProdHostsForCust -----------------------------------------------------------
# Parameters ($custcode)
# Returns array list of managed hostnames.
# This list comes from the authoritative list of managed hosts in the
# Nagios system. 
sub listProdHostsForCust { 
	my $custcode = shift;

	return `/usr/bin/nq-listhosts.pl -c $custcode -e "prod"`;
}



1
