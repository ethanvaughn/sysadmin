package lib::ip;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::ipaddr;
use lib::sn;
use lib::ipfunc;


#===== ipaddr Table ==========================================================

#----- getIpList ---------------------------------------------------------
# Get a list of all ip addresses. 
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getIpList {
	my $dbh = shift;
	
	my $data = dao::ipaddr::getIpList( $dbh );
	foreach my $rec (@$data) {
		$rec->{ipaddr} = lib::ipfunc::int2ip( $rec->{ipaddr} );
		if ($rec->{net}) {
			$rec->{net}    = lib::ipfunc::int2ip( $rec->{net} );
		}
		if ($rec->{mask}) {
			$rec->{mask}   = lib::ipfunc::int2ip( $rec->{mask} );
		}
	}

	return $data;
}



#----- getIpListBySn -------------------------------------------------------
# Get list if IPs for a given subnet_id. 
# Arguments: ($dbh, subnet_id)
# Returns: AoH = standard dataset:
sub getIpListBySn {
	my $dbh = shift;
	my $subnet_id = shift;
	
	my $data = dao::ipaddr::getIpListForSn( $dbh, $subnet_id );

	foreach my $rec (@$data) {
		$rec->{ipaddr} = lib::ipfunc::int2ip( $rec->{ipaddr} );
		$rec->{net}    = lib::ipfunc::int2ip( $rec->{net} );
		$rec->{mask}   = lib::ipfunc::int2ip( $rec->{mask} );
	}

	return $data;
}



#----- getIpListPerSn -------------------------------------------------------
# Get list of all IPs wrapped in a hash keyed by subnet_id. 
# Arguments: ($dbh)
# Returns: Ho(AoH) = Hash of (Array of Hashes). The AoH is a list of IP recs.
# Each list is referenced by the corresponding subnet id for display purposes.
sub getIpListPerSn {
	my $dbh = shift;
	
	my $data;
	
	my $snlist = lib::sn::getSnList( $dbh );

	foreach my $rec (@$snlist) {
		my $tmp = dao::ipaddr::getIpListForSn( $dbh, $rec->{id} );
		$data->{$rec->{id}} = $tmp;
	}

	return $data;
}



#----- getIpListForItem -------------------------------------------------------
# Get list of IPs for a given item. 
# Arguments: ($dbh, item_id)
# Returns: AoH list of IP recs.
sub getIpListForItem {
	my $dbh       = shift;
	my $item_id = shift;
	
	my $data = dao::ipaddr::getIpListForItem( $dbh, $item_id );

	# Translate to ip for use with view:
	foreach my $rec (@$data) {
		$rec->{ipaddr}  = lib::ipfunc::int2ip( $rec->{ipaddr} );
		delete( $rec->{adminip} ) if (!$rec->{adminip});
	}

	return $data;
}



#----- getAdminIp -------------------------------------------------------
# Get the admin IP for this item.
sub getAdminIp {
	my $dbh     = shift;
	my $item_id = shift;
	
	if (!$item_id) {
		return 0;
	}
	
	my $data = dao::ipaddr::getAdminIp( $dbh, $item_id );
		
	# Translate to ip for use with view:
	foreach my $rec (@$data) {
		$rec->{ipaddr}  = lib::ipfunc::int2ip( $rec->{ipaddr} );		
	}

	return $data;
}



#----- getIpById ---------------------------------------------------------
# Get details for a single IP address rec. 
# Arguments: ($dbh, $id)
# Returns: Hash ref.
sub getIpById {
	my $dbh = shift;
	my $id = shift;

	my $data = dao::ipaddr::getIp( $dbh, ["id", $id] );
	
	# Translate to ip for use with view:
	if ($data->{ipaddr}) {
		$data->{ipaddr}  = lib::ipfunc::int2ip( $data->{ipaddr} );
	}
	
	return $data;
}



#----- getIpByAddr -------------------------------------------------------
# Get details for a single ipaddr. 
# Arguments: ($dbh, $name)
# Returns: Hash ref.
sub getIpByAddr {
	my $dbh = shift;
	my $ipaddr = shift;
	
	$ipaddr = lib::ipfunc::ip2int(  $ipaddr ); 
	
	my $data = dao::ipaddr::getIp( $dbh, ["ipaddr", $ipaddr] );

	if ($data->{ipaddr}) {
		$data->{ipaddr} = lib::ipfunc::int2ip( $data->{ipaddr} );
	}

	return $data;
}



#----- addIp ------------------------------------------------------
sub addIp {
	my $dbh = shift;
	my $rec = shift;
	
	# Translate ip to int for use with database:
	$rec->{ipaddr}  = lib::ipfunc::ip2int( $rec->{ipaddr} );
	
	if ($rec->{item_id} == 0) {
		$rec->{item_id} = "NULL";
	}
	
	my $adminip = "FALSE";
	if (defined( $rec->{adminip} )) {
		$adminip = "TRUE";
	}
	$rec->{adminip} = $adminip;

	dao::ipaddr::addIp( $dbh, $rec );

	# Translate back to ip to send back to view:
	$rec->{ipaddr}  = lib::ipfunc::int2ip( $rec->{ipaddr} );
	
	return;
}



#----- updateIp ------------------------------------------------------
sub updateIp {
	my $dbh = shift;
	my $rec = shift;
	
#print STDERR "DEBUG: lib::updateIP \n";
#foreach my $key (keys( %$rec )) {
#	print STDERR "DEBUG: $key = $rec->{$key}\n";
#}

	# Translate ip to int for use with database:
	$rec->{ipaddr}  = lib::ipfunc::ip2int( $rec->{ipaddr} );
	
	if ($rec->{item_id} == 0) {
		$rec->{item_id} = "NULL";
	}

	my $adminip = "FALSE";
	if (defined( $rec->{adminip} )) {
		$adminip = "TRUE";
	}
	$rec->{adminip} = $adminip;
	

	dao::ipaddr::updateIp( $dbh, $rec );

	# Translate back to ip to send back to view:
	$rec->{ipaddr}  = lib::ipfunc::int2ip( $rec->{ipaddr} );
	
	return;
}



#----- delIp ------------------------------------------------------
sub delIp {
	my $dbh = shift;
	my $ipaddr_id = shift;

	dao::ipaddr::clearTypeLink( $dbh, $ipaddr_id );
	dao::ipaddr::delIp( $dbh, ["id",$ipaddr_id] );
	
	return;
}





#===== iptype Table ==========================================================

#----- getIpTypeList ---------------------------------------------------------
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getIpTypeList {
	my $dbh = shift;

	return dao::ipaddr::getIpTypeList( $dbh );
}



#----- getIpTypeById -------------------------------------------------------
# Arguments: ($dbh, $type_id)
sub getIpTypeById {
	my $dbh = shift;
	my $type_id = shift;

	return dao::ipaddr::getIpType( $dbh, ["id", $type_id] );
}



#----- addIpType ------------------------------------------------------
sub addIpType {
	my $dbh = shift;
	my $rec = shift;
	
	return dao::ipaddr::addIpType( $dbh, $rec );
}



#----- updateIpType ------------------------------------------------------
sub updateIpType {
	my $dbh = shift;
	my $rec = shift;
	
	return dao::ipaddr::updateIpType( $dbh, $rec );
}



#----- delIpType ------------------------------------------------------
sub delIpType {
	my $dbh = shift;
	my $type_id = shift;
	
	return dao::ipaddr::delIpType( $dbh, ["id",$type_id] );
}





#===== iptypelink Table ==========================================================

#----- getTypeLink -------------------------------------------------------
# Arguments: ($dbh, $ipaddr_id)
sub getTypeLink {
	my $dbh = shift;
	my $ipaddr_id = shift;

	my $rec = dao::ipaddr::getTypeLink( $dbh, $ipaddr_id );

	return $rec->{iptype_id};
}



#----- setTypeLink ---------------------------------------------------------------
sub setTypeLink {
	my $dbh = shift;
	my $ipaddr_id = shift;
	my $type_id = shift;

	return dao::ipaddr::setTypeLink( $dbh, $ipaddr_id, $type_id );
}





1;
