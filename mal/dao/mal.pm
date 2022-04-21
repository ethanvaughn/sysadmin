package dao::mal;


use strict;


#----- getList ---------------------------------------------------------------
# Get list of all records.
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT
		id,
		hostname,
		ip,
		servicename,
		event_time,
		msg,
		username,
		level,
		status
	FROM mal
	ORDER BY event_time
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	
	return \@data;
}




#----- getClosedList ---------------------------------------------------------------
# Get list of closed records.
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getClosedList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT
		id,
		hostname,
		ip,
		servicename,
		event_time,
		msg,
		username,
		level,
		status
	FROM mal
	WHERE status is NOT NULL
	ORDER BY event_time DESC;
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	
	return \@data;
}




#----- getOpenList ---------------------------------------------------------------
# Get list of open records.
# Arguments: ($dbh)
# Returns: Array ref of hashes (AOH).
sub getOpenList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT
		id,
		hostname,
		ip,
		servicename,
		event_time,
		msg,
		username,
		level,
		status
	FROM mal
	WHERE status is NULL
	ORDER BY event_time;
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	
	return \@data;
}




#----- getOpenListByService ---------------------------------------------------------------
# Get list of open records for a specific host and service.
# Arguments: ($dbh, $hostname, $servicename)
# Returns: Array ref of hashes (AOH).
sub getOpenListByService {
	my $dbh = shift;
	my $hostname = shift;
	my $servicename = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT
		id,
		hostname,
		ip,
		servicename,
		event_time,
		msg,
		username,
		level,
		status
	FROM mal
	WHERE status is NULL
	AND servicename = '$servicename'
	AND hostname = '$hostname'
	ORDER BY event_time;
SQL
	my $sth = $dbh->prepare( $sql );
	$sth->execute();
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	
	return \@data;
}




#----- insertRec ----------------------------------------------------------------
# Parameters: ($dbh, $rec)
# Returns: Nothing.
sub insertRec {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		INSERT INTO mal (
			hostname,
			ip,
			servicename,
			event_time,
			level,
			msg
		) VALUES (
			'$rec->{hostname}',
			'$rec->{ip}',
			'$rec->{servicename}',
			'$rec->{event_time}',
			'$rec->{level}',
			'$rec->{msg}'
		)
SQL

	$dbh->do( $sql );
}



#----- closeRec ----------------------------------------------------------------
# Set status to Now().
# Parameters: ($dbh, $rec)
# Returns: Nothing.
sub closeRec {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE mal SET
		username   = '$rec->{username}',
	    status     = 'Now()'
		WHERE id = $rec->{id}
SQL

	$dbh->do( $sql );
}



#----- delRec ----------------------------------------------------------------
# Delete a single record.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (id, "5") 
# Returns: nothing.
sub delRec {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
		DELETE FROM mal
		WHERE $param->[0] = '$param->[1]'
SQL

	$dbh->do( $sql );
}



1;
