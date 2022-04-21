package dao::company;

use lib::time;

use strict;

#----- getCompanyList ---------------------------------------------------------------
# Get a list of all companies.
# Arguments: ($dbh)
# Returns: Standard fetchall_hashref
sub getCompanyList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
	SELECT  
		id,
		name,
		code
	FROM company
	ORDER BY name
SQL

	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute()                 || return 0;

	my $rec = $sth->fetchall_hashref( 'name' );
	$sth->finish;
	
	return $rec;

}



#----- getCompany ---------------------------------------------------------------
# Get detail for a single company.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (code, "TMX") 
# Returns: hashref of the company record.
sub getCompany {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		name,
		code
	FROM company
	WHERE $param->[0] = ?
SQL
	
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute( $param->[1] )    || return 0;
	return $sth->fetchrow_hashref();
}



#----- addCompany ----------------------------------------------------------------
# Insert new company into the "company" table. 
# Returns: Nothing.
sub addCompany {
	my $dbh = shift;
	my $rec = shift;

	my $sql = "INSERT INTO company ( name, code ) VALUES ( ?, ? )";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{name}, $rec->{code} );
}



#----- updateCompany ----------------------------------------------------------------
# Returns: Nothing.
sub updateCompany {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE company SET
		name  = ?,
		code  = ?,
		mtime = 'NOW()'
		WHERE id = ?
SQL
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{name}, $rec->{code}, $rec->{id} );
}



#----- delCompany ----------------------------------------------------------------
# Delete a single company.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (code, "TMX") 
# Returns: nothing.
sub delCompany {
	my $dbh   = shift;
	my $param = shift;

	my $sql = "DELETE FROM company WHERE $param->[0] = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $param->[1] );
}


1;
