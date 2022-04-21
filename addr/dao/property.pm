package dao::property;

use lib::time;

use strict;


#----- getPropList -----------------------------------------------------------------
sub getPropList {
	my $dbh    = shift;
	
	my $sql = <<SQL;
		SELECT
			id,
			name,
			type
		FROM prop
		ORDER BY name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my $rec = $sth->fetchall_hashref( 'name' );
	$sth->finish;
	
	return $rec;
}




#----- getPropValues -----------------------------------------------------------------
sub getPropValues {
	my $dbh    = shift;
	my $prop_id = shift;
	
	my $sql = <<SQL;
		SELECT
			prop.id,
			prop.name,
			prop.type,
			propval.id as propval_id,
			propval.value
		FROM prop,propval
		WHERE prop.id = propval.prop_id
		AND prop.id = ?;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $prop_id )              || return 0;

	my $rec = $sth->fetchall_hashref( 'value' );
	$sth->finish;
	
	return $rec;
}




#----- getPropertyById ---------------------------------------------------------------
# Get detail for a single property.
# Arguments: ($dbh, $id)
# Returns: hashref of the property record.
sub getPropertyById {
	my $dbh = shift;
	my $id = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		name,
		value
	FROM property
	WHERE id = '$id'
SQL
	
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute()                 || return 0;
	return $sth->fetchrow_hashref();
}



#----- getPropertyByName ---------------------------------------------------------------
# Get detail for a single property.
# Arguments: ($dbh, $name, $value)
# Must have both the name and the value to find a unique property to return.
# Returns: hashref of the property record.
sub getPropertyByName {
	my $dbh = shift;
	my $name = shift;
	my $value = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		name,
		value
	FROM property
	WHERE name = '$name'
	AND  value = '$value'
SQL
	
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute()                 || return 0;
	return $sth->fetchrow_hashref();
}



#----- getPropId ----------------------------------------------------------------
# Return the id of the named property.
sub getPropId {
	my $dbh      = shift;
	my $propname = shift;
	
	my $id = 0;
	if (!$propname) {
		return $id;
	}
	
	my $sql = "SELECT id FROM prop WHERE name = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute( $propname )      || return 0;
	
	my $row = $sth->fetchrow_hashref();
	$id = $row->{id};
	
	return $id;
}




#----- getPropValId ----------------------------------------------------------------
# Return the id of the value for the given property id and value.
sub getPropValId {
	my $dbh     = shift;
	my $prop_id  = shift;
	my $propval = shift;

	my $id = 0;

	if (!$propval) {
		return 0;
	}
	
	my $sql = "SELECT id FROM propval WHERE prop_id = ? AND value = ?";
	my $sth = $dbh->prepare( $sql )     || return 0;
	$sth->execute( $prop_id, $propval ) || return 0;
	
	my $row = $sth->fetchrow_hashref();
	$id = $row->{id};
	
	return $id;
}




#----- getPropTemplateList ---------------------------------------------------------------
# Get a list of templates for a given property id. 
# Arguments: ($dbh)
# Returns: standard fetchall_hashref with name as the key. 
sub getPropTemplateList {
	my $dbh    = shift;
	my $prop_id = shift;

	my $sql = <<SQL;
		SELECT  
			template.id,
			template.name,
			prop.id as prop_id,
			prop.name as propname,
			prop.type as proptype
		FROM template,prop,proptemplatelink
		WHERE template.id = proptemplatelink.template_id
		AND prop.id = proptemplatelink.prop_id
		AND prop.id = ?
		ORDER BY template.name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $prop_id )              || return 0;

	my $rec = $sth->fetchall_hashref( 'name' );
	$sth->finish;
	
	return $rec;
}




#----- addProperty ----------------------------------------------------------------
# Insert new property into the "property" table. 
# Returns: Nothing.
sub addProperty {
	my $dbh = shift;
	my $rec = shift;
	
	my $sql = "INSERT INTO prop (name,type) VALUES (?,?)";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{propname}, $rec->{proptype} );
}





#----- addPropVal ----------------------------------------------------------------
# Insert new property value into the "propval" table. 
# Returns: Nothing.
sub addPropVal {
	my $dbh = shift;
	my $rec = shift;

	my $sql = "INSERT INTO propval (prop_id,value) VALUES (?,?)";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{prop_id}, $rec->{propval} );
}




#----- updateProperty ----------------------------------------------------------------
# Returns: Nothing.
sub updateProperty {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE prop SET
			name  = ?,
			type  = ?,
			mtime = 'NOW()'
		WHERE id = ?
SQL

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{propname}, $rec->{proptype}, $rec->{prop_id} );
}




#----- updatePropVal ----------------------------------------------------------------
# Returns: Nothing.
sub updatePropVal {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE propval SET
			prop_id  = ?,
			value    = ?,
			mtime    = 'NOW()'
		WHERE id = ?
SQL

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{prop_id}, $rec->{propval}, $rec->{propval_id} );
}




#----- delProperty ----------------------------------------------------------------
# Delete a single property.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (value, "TMX") 
# Returns: nothing.
sub delProperty {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
		DELETE FROM prop
		WHERE $param->[0] = ?
SQL
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $param->[1] );
}




#----- delPropVal ----------------------------------------------------------------
# Delete a single propval by the propval.id.
# Arguments: ($dbh, id)
# Returns: nothing.
sub delPropVal {
	my $dbh = shift;
	my $id  = shift;

	my $sql = "DELETE FROM propval WHERE id = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $id );
}




#----- clearTmplLinks --------------------------------------------------------
sub clearTmplLinks {
	my $dbh    = shift;
	my $prop_id = shift;
	
	my $sql = "DELETE FROM proptemplatelink WHERE prop_id = ?";

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $prop_id );
}





#----- setTmplLink ------------------------------------------------------------
sub setTmplLink {
	my $dbh    = shift;
	my $prop_id = shift;
	my $tmplid = shift;

	my $sql = "INSERT INTO proptemplatelink (prop_id, template_id) VALUES( ?, ?)";
	my $sth = $dbh->prepare( $sql ) || return 0;
	
	return $sth->execute( $prop_id, $tmplid );
}


1;
