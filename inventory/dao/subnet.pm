package dao::subnet;


use strict;



#===== subnet Table ==========================================================

#----- getSnList ---------------------------------------------------------------
# Get a flat list of all subnets.
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getSnList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT  
		id,
		net,
		mask,
		comment,
		vlan
	FROM subnet
	ORDER BY net ASC
SQL

	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	return \@data;
}



#----- getSn ---------------------------------------------------------------
# Get detail for a single subnet.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (net, "654323") 
# Returns: hashref of the ipaddr record.
sub getSn {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		net,
		mask,
		comment,
		vlan
	FROM subnet
	WHERE $param->[0] = '$param->[1]'
SQL
	
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	return $sth->fetchrow_hashref();
}



#----- addSn ----------------------------------------------------------------
# Insert new record into the "subnet" table. 
# Returns: Nothing.
sub addSn {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		INSERT INTO subnet (
			net,
			mask,
			comment,
			vlan
		)
		VALUES (
			'$rec->{net}',
			'$rec->{mask}',
			'$rec->{comment}',
			'$rec->{vlan}'
		)
SQL

	$dbh->do( $sql );
}



#----- updateSn ----------------------------------------------------------------
# Returns: Nothing.
sub updateSn {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE subnet SET
		net     = '$rec->{net}',
		mask    = '$rec->{mask}',
		comment = '$rec->{comment}',
		vlan    = '$rec->{vlan}',
		mtime = 'NOW()'
		WHERE id = '$rec->{id}'
SQL

	$dbh->do( $sql );
}



#----- delSn ----------------------------------------------------------------
# Delete a single subnet.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (id, "5") 
# Returns: nothing.
sub delSn {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
		DELETE FROM subnet
		WHERE $param->[0] = '$param->[1]'
SQL

	$dbh->do( $sql );
}



1;
