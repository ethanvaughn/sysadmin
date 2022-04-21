package dao::ipaddr;


use strict;


#===== ipaddr Table ==========================================================

#----- getIpList ---------------------------------------------------------------
# Get a flat list of all ip addresses.
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getIpList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT  
		a.id,
		a.ipaddr,
		a.adminip,
		a.comment,
		a.item_id,
		a.subnet_id,
		d.itemname,
		d.comment as item_comment,
		s.net,
		s.mask,
		s.comment as sn_comment
	FROM ipaddr as a
	LEFT OUTER JOIN item as d ON (a.item_id = d.id)
	LEFT OUTER JOIN subnet as s ON (a.subnet_id = s.id)
	ORDER BY a.ipaddr ASC
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	
	return \@data;
}



#----- getIpListForSn ---------------------------------------------------------------
# Get a flat list of all ip addresses for a given subnet id.
# Arguments: ($dbh, subnet_id)
# Returns: Array ref of hashes (AOH).
sub getIpListForSn {
	my $dbh = shift;
	my $subnet_id = shift;

	my @data;

	my $sql = <<SQL;
	SELECT  
		a.id,
		a.ipaddr,
		a.adminip,
		a.comment,
		a.item_id,
		a.subnet_id,
		i.itemname,
		i.comment as item_comment,
		s.net,
		s.mask,
		s.comment as sn_comment
	FROM ipaddr as a
	LEFT OUTER JOIN item as i ON (a.item_id = i.id)
	LEFT OUTER JOIN subnet as s ON (a.subnet_id = s.id)
	WHERE subnet_id = $subnet_id
	ORDER BY ipaddr ASC
SQL

	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	return \@data;
}



#----- getIpListForItem ----------------------------------------------------
# Get IPs for a given item.
# Arguments: ($dbh, item_id)
# Returns: Array ref of hashes (AoH).
sub getIpListForItem {
	my $dbh = shift;
	my $item_id = shift;

	my @data;

	my $sql = <<SQL;
	SELECT
		ipaddr.id,
		ipaddr.ipaddr,
		ipaddr.adminip,
		ipaddr.comment,
		iptype.name as iptype
	FROM ipaddr
	LEFT OUTER JOIN iptypelink ON (ipaddr.id = iptypelink.ipaddr_id)
	LEFT OUTER JOIN iptype ON (iptype.id = iptypelink.iptype_id)
	LEFT OUTER JOIN item ON (ipaddr.item_id = item.id)
	WHERE ipaddr.item_id = $item_id
	ORDER BY ipaddr ASC
SQL

	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	return \@data;
}



#----- getAdminIp ----------------------------------------------------
sub getAdminIp {
	my $dbh = shift;
	my $item_id = shift;

	my @data;

	my $sql = <<SQL;
	SELECT
		ipaddr.id,
		ipaddr.ipaddr
	FROM ipaddr
	LEFT OUTER JOIN item ON (ipaddr.item_id = item.id)
	WHERE ipaddr.item_id = $item_id
	AND ipaddr.adminip='TRUE'
SQL

	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}

	return \@data;
}



#----- getIp ---------------------------------------------------------------
# Get detail for a single ip address.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (ipaddr, "654321") 
# Returns: hashref of the ipaddr record.
sub getIp {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		ipaddr,
		comment,
		item_id,
		subnet_id
	FROM ipaddr
	WHERE $param->[0] = '$param->[1]'
SQL
	
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	return $sth->fetchrow_hashref();
}



#----- addIp ----------------------------------------------------------------
# Insert new ip address into the "ipaddr" table. 
# Returns: Nothing.
sub addIp {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		INSERT INTO ipaddr (
			ipaddr,
			adminip,
			comment,
			item_id,
			subnet_id
		)
		VALUES (
			'$rec->{ipaddr}',
			'$rec->{adminip}',
			'$rec->{comment}',
			$rec->{item_id},
			$rec->{subnet_id}
		)
SQL

	$dbh->do( $sql );
}



#----- updateIp ----------------------------------------------------------------
# Returns: Nothing.
sub updateIp {
	my $dbh = shift;
	my $rec = shift;

	my $item_id = qq|'$rec->{item_id}'|;
	if ($rec->{item_id} eq "NULL") {
		$item_id = "NULL";
	}


	my $sql = <<SQL;
		UPDATE ipaddr SET
		ipaddr    = '$rec->{ipaddr}',
		adminip   = '$rec->{adminip}',
		comment   = '$rec->{comment}',
		item_id   = $item_id,
		subnet_id = '$rec->{subnet_id}',
		mtime     = 'NOW()'
		WHERE id  = '$rec->{id}'
SQL

	$dbh->do( $sql );
}



#----- delIp ----------------------------------------------------------------
# Delete a single ip address.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (id, "5") 
# Returns: nothing.
sub delIp {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
		DELETE FROM ipaddr
		WHERE $param->[0] = '$param->[1]'
SQL

	$dbh->do( $sql );
}





#===== iptype Table ==========================================================

#----- getIpTypeList ---------------------------------------------------------------
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getIpTypeList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT  
		id,
		name
	FROM iptype
	ORDER BY name ASC
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	return \@data;
}



#----- getIpType ---------------------------------------------------------------
# Get detail for a single iptype rec.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (id, "41") 
# Returns: hashref of the ipaddr record.
sub getIpType {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		name
	FROM iptype
	WHERE $param->[0] = '$param->[1]'
SQL
	
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	return $sth->fetchrow_hashref();
}



#----- addIpType ----------------------------------------------------------------
# Returns: Nothing.
sub addIpType {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		INSERT INTO iptype (name)
		VALUES ('$rec->{name}')
SQL

	$dbh->do( $sql );
}



#----- updateIpType ----------------------------------------------------------------
# Returns: Nothing.
sub updateIpType {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE iptype SET
		name = '$rec->{name}',
		mtime = 'NOW()'
		WHERE id = '$rec->{id}'
SQL

	$dbh->do( $sql );
}



#----- delIpType ----------------------------------------------------------------
# Delete a single ip type record.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (name, "FOO") 
# Returns: nothing.
sub delIpType {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
		DELETE FROM iptype
		WHERE $param->[0] = '$param->[1]'
SQL

	$dbh->do( $sql );
}





#===== iptypelink Table ==========================================================

#----- getTypeLink ---------------------------------------------------------------
# Arguments: ($dbh, $ipaddr_id)
# Returns: hashref of the iptype record for this ipaddr_id;
sub getTypeLink {
	my $dbh = shift;
	my $ipaddr_id = shift;

	my $sql = "SELECT iptype_id FROM iptypelink WHERE ipaddr_id=$ipaddr_id;" ;
	
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	return $sth->fetchrow_hashref();
}



#----- setTypeLink -------------------------------------------------------
# Arguments: ($dbh, $ipaddr_id, iptype_id)
# Returns: nothing.
sub setTypeLink {
	my $dbh = shift;
	my $ipaddr_id = shift;
	my $iptype_id = shift;

	# First clean up any references to this item in the iptypelink table:
	clearTypeLink( $dbh, $ipaddr_id );

	# Insert this relationship:
	my $sql = "INSERT INTO iptypelink (ipaddr_id, iptype_id) VALUES($ipaddr_id, $iptype_id)";
	$dbh->do( $sql );
}



#----- clearTypeLink -------------------------------------------------------
# Arguments: ($dbh, $ipaddr_id)
# Returns: nothing.
sub clearTypeLink {
	my $dbh = shift;
	my $ipaddr_id = shift;

	my $sql = "DELETE FROM iptypelink WHERE ipaddr_id=$ipaddr_id";

	$dbh->do( $sql );
}



1;
