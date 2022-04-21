package dao::group;


#----- addGroup --------------------------------------------------------
# parameters: (dbh, gid, groupname)
sub addGroup {
	my $dbh = shift;
	my $gid = shift;
	my $groupname = shift;

	my $sqlstr = <<SQL;
	INSERT INTO posixgroup (
		gid,
		name
	)
	VALUES ( ?, ? )
SQL

	my $sth = $dbh->prepare( $sqlstr );
	$sth->execute( $gid, $groupname );
}




#----- addUserToGroup --------------------------------------------------------
# parameters: (dbh, username, groupname)
sub addUserToGroup {
	my $dbh = shift;
	my $username = shift;
	my $groupname = shift;

	my $sqlstr = <<SQL;
	INSERT INTO accountgrouplink (
		accountname,
		groupname
	)
	VALUES ( ?, ? )
SQL

	my $sth = $dbh->prepare( $sqlstr );
	$sth->execute( $username, $groupname );
}


#----- getNextGid -------------------------------------------------------
# parameters: (dbh, name)
# returns scalar containing next GID in the posixgroup table.
sub getNextGid {
	my $dbh = shift;

	my @row = $dbh->selectrow_array( "SELECT gid FROM posixgroup ORDER BY gid DESC" );
	return $row[0] + 1;
}



#----- getGidByName -------------------------------------------------------
# parameters: (dbh, name)
# returns scalar containing GID for the group name.
sub getGidByName {
	my $dbh = shift;
	my $name = shift;

	my @row = $dbh->selectrow_array( "SELECT gid FROM posixgroup WHERE name='$name'" );

	return $row[0];
}



#----- getAllGroups ------------------------------------------------------
# parameters: (dbh)
# returns hashref to the dataset containing all groups.
sub getAllGroups {
	my $dbh = shift;

	my $sqlstr = <<SQL;
		SELECT  name, gid
		FROM posixgroup 
		ORDER BY name
SQL

    return $dbh->selectall_hashref( $sqlstr, "name" );
}



#----- getUserGroupLinks -------------------------------------------------------
# parameters: (dbh)
# returns hashref to the dataset containing all user-group links.
sub getUserGroupLinks {
	my $dbh = shift;


	my $sqlstr = <<SQL;
		SELECT  accountname, groupname
		FROM accountgrouplink
SQL

    return $dbh->selectall_arrayref( $sqlstr );
}



#----- setGroupName --------------------------------------------------------
# parameters: (dbh, groupname, newname)
sub setGroupName {
	my $dbh = shift;
	my $groupname = shift;
	my $newname = shift;
	
	my $sqlstr = <<SQL;
	UPDATE posixgroup SET 
	name=?
	WHERE name=?
SQL

	my $sth = $dbh->prepare( $sqlstr );
	$sth->execute( $newname, $groupname );
}



#----- deleteGroup ------------------------------------------------------------
# Delete the group. Due to database foreign key cascade, user-group links 
# referring to this group will also be deleted. However, if the group is 
# referenced as the primary group of a user, a db exception will be thrown.
# You cannot delete a group that is currently in use as a user's primary.
# Parameters: (dbh, groupname)
sub deleteGroup {
	my $dbh = shift;
	my $groupname = shift;


	my $sqlstr = "DELETE FROM posixgroup WHERE name=\'$groupname\'";
	$dbh->do( $sqlstr );
}



1;
