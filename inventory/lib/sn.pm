package lib::sn;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::subnet;
use lib::ipfunc;



#----- getSnList ---------------------------------------------------------
# Get a list of all ip addresses. 
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getSnList {
	my $dbh = shift;
	
	my $data =  dao::subnet::getSnList( $dbh );
	# Transform the integers into human-readable ip addresses for use in views:
	foreach my $rec (@$data) {
		$rec->{net}  = lib::ipfunc::int2ip( $rec->{net} );
		$rec->{mask} = lib::ipfunc::int2ip( $rec->{mask} );
	}
	
	return $data;
}



#----- getSnById ---------------------------------------------------------
# Get details for a single subnet rec. 
# Arguments: ($dbh, $id)
# Returns: Hash ref.
sub getSnById {
	my $dbh = shift;
	my $id = shift;

	my $data = dao::subnet::getSn( $dbh, ["id", $id] );
	
	# Translate to ip for use with view:
	$data->{net}  = lib::ipfunc::int2ip( $data->{net} );
	$data->{mask} = lib::ipfunc::int2ip( $data->{mask} );
	
	return $data;
}



#----- getSnByNet -------------------------------------------------------
# Get details for a single subnet. 
# Arguments: ($dbh, $net)
# Returns: Hash ref.
sub getSnByNet {
	my $dbh = shift;
	my $net = shift;

	# Translate ip to int for use with database:
	$net = lib::ipfunc::ip2int( $net );
	my $data = dao::subnet::getSn( $dbh, ["net", $net] );

	# Translate to ip for use with view:
	$data->{net}  = lib::ipfunc::int2ip( $data->{net} );
	$data->{mask} = lib::ipfunc::int2ip( $data->{mask} );
	
	return $data;
}



#----- addSn ------------------------------------------------------
sub addSn {
	my $dbh = shift;
	my $rec = shift;
	
	# Translate ip to int for use with database:
	$rec->{net}  = lib::ipfunc::ip2int( $rec->{net} );
	$rec->{mask} = lib::ipfunc::ip2int( $rec->{mask} );
	
	dao::subnet::addSn( $dbh, $rec );

	# Translate back to ip to send back to view:
	$rec->{net}  = lib::ipfunc::int2ip( $rec->{net} );
	$rec->{mask} = lib::ipfunc::int2ip( $rec->{mask} );
	
	return;
}



#----- updateSn ------------------------------------------------------
sub updateSn {
	my $dbh = shift;
	my $rec = shift;
	
	# Translate ip to int for use with database:
	$rec->{net}  = lib::ipfunc::ip2int( $rec->{net} );
	$rec->{mask} = lib::ipfunc::ip2int( $rec->{mask} );
	
	dao::subnet::updateSn( $dbh, $rec );

	# Translate back to ip to send back to view:
	$rec->{net}  = lib::ipfunc::int2ip( $rec->{net} );
	$rec->{mask} = lib::ipfunc::int2ip( $rec->{mask} );
	
	return;
}



#----- delSn ------------------------------------------------------
sub delSn {
	my $dbh = shift;
	my $subnet_id = shift;

	dao::subnet::delSn( $dbh, ["id",$subnet_id] );
	
	return;
}




1;
