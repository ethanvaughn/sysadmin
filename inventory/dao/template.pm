package dao::template;

use lib::time;

use strict;




#----- getTemplateList ---------------------------------------------------------------
# Get a list of all templates.
# Arguments: ($dbh)
# Returns: standard fetchall_hashref with name as the key. 
sub getTemplateList {
	my $dbh = shift;

	my @data;
	
	my $sql = <<SQL;
		SELECT  
			id,
			name
		FROM template
		ORDER BY name
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my $rec = $sth->fetchall_hashref( 'name' );
	$sth->finish;
	
	return $rec;
}




#----- getTemplatePropList ---------------------------------------------------------------
# Get a list of properties for a given template id. 
# Arguments: ($dbh)
# Returns: standard fetchall_hashref with name as the key. 
sub getTemplatePropList {
	my $dbh    = shift;
	my $tmplid = shift;

	my $sql = <<SQL;
		SELECT  
			prop.id,
			prop.name,
			prop.type as proptype,
			template.id as tmplid,
			template.name as tmplname
		FROM template,prop,proptemplatelink
		WHERE template.id = proptemplatelink.template_id
		AND prop.id = proptemplatelink.prop_id
		AND template.id = ?
		ORDER BY prop.name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $tmplid )               || return 0;

	my $rec = $sth->fetchall_hashref( 'name' );
	$sth->finish;
	
	return $rec;
}




#----- getTemplateFieldList ---------------------------------------------------------------
# Get a list of fields for this template that will be shown on the main screen. 
# Arguments: ($dbh, tmplid)
# Returns: standard fetchall_hashref with field_name as the key. 
sub getTemplateFieldList {
	my $dbh    = shift;
	my $tmplid = shift;

	my $sql = "SELECT field_name,field_order FROM itemlistfields WHERE template_id = ?";

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $tmplid )               || return 0;

	my $rec = $sth->fetchall_hashref( 'field_name' );
	$sth->finish;
	
	return $rec;
}




#----- getTemplate ---------------------------------------------------------------
# Get detail for a single template.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (code, "TMX") 
# Returns: hashref of the Template record.
sub getTemplate {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		id,
		name
	FROM template
	WHERE $param->[0] = ?
SQL
	
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute( $param->[1] )    || return 0;

	return $sth->fetchrow_hashref();
}




#----- getTemplateId ----------------------------------------------------------------
# Return the id of the named template.
sub getTemplateId {
	my $dbh      = shift;
	my $tmplname = shift;
	
	my $id = 0;
	if (!$tmplname) {
		return $id;
	}
	
	my $sql = "SELECT id FROM template WHERE name = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute( $tmplname )      || return 0;
	
	my $row = $sth->fetchrow_hashref();
	$id = $row->{id};
	
	return $id;
}




#----- useFieldUsers ----------------------------------------------------------------
# Look up this template id in the usertamplatlink table to determine if the "Users" 
# field is assigned to this template type.
# Return true (in the form of the tmplid) if tmplid exists in the table usertemplatelink.
sub useFieldUsers {
	my $dbh    = shift;
	my $tmplid = shift;
	
	my $id = 0;
	if (!$tmplid) {
		return $id;
	}
	
	my $sql = "SELECT template_id FROM usertemplatelink WHERE template_id = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	$sth->execute( $tmplid )      || return 0;
	
	my $row = $sth->fetchrow_hashref();
	$id = $row->{template_id};
	
	return $id;
}




#----- addTemplate ----------------------------------------------------------------
# Insert new Template into the "Template" table. 
# Returns: Nothing.
sub addTemplate {
	my $dbh = shift;
	my $rec = shift;

	my $sql = "INSERT INTO template (name) VALUES (?)";
	my $sth = $dbh->prepare( $sql )   || return 0;
	return $sth->execute( $rec->{tmplname} );
}




#----- updateTemplate ----------------------------------------------------------------
# Returns: Nothing.
sub updateTemplate {
	my $dbh = shift;
	my $rec = shift;

	my $sql = "UPDATE template SET name = ?, mtime = 'NOW()' WHERE id = ?";

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $rec->{tmplname}, $rec->{tmplid} );
}




#----- delTemplate ----------------------------------------------------------------
# Delete a single Template.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (code, "TMX") 
# Returns: nothing.
sub delTemplate {
	my $dbh = shift;
	my $param = shift;

	my $sql = "DELETE FROM template WHERE $param->[0] = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $param->[1] );
}




#----- clearUserLink --------------------------------------------------------
sub clearUserLink {
	my $dbh    = shift;
	my $tmplid = shift;
	
	my $sql = "DELETE FROM usertemplatelink WHERE template_id = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $tmplid );
}




#----- setUserLink ------------------------------------------------------------
sub setUserLink {
	my $dbh    = shift;
	my $tmplid = shift;

	my $sql = "INSERT INTO usertemplatelink (template_id) VALUES( ? )";
	my $sth = $dbh->prepare( $sql )  || return 0;
	return $sth->execute( $tmplid );
}




#----- clearPropLinks --------------------------------------------------------
sub clearPropLinks {
	my $dbh    = shift;
	my $tmplid = shift;
	
	my $sql = "DELETE FROM proptemplatelink WHERE template_id = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $tmplid );
}




#----- setPropLink ------------------------------------------------------------
sub setPropLink {
	my $dbh    = shift;
	my $tmplid = shift;
	my $propid = shift;

	my $sql = "INSERT INTO proptemplatelink (template_id, prop_id) VALUES( ?, ? )";
	my $sth = $dbh->prepare( $sql )  || return 0;
	return $sth->execute( $tmplid, $propid );
}




#----- clearTemplateFields --------------------------------------------------------
sub clearTemplateFields {
	my $dbh    = shift;
	my $tmplid = shift;
	
	my $sql = "DELETE FROM itemlistfields WHERE template_id = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $tmplid );
}




#----- setTemplateField ------------------------------------------------------------
sub setTemplateField {
	my $dbh    = shift;
	my $tmplid = shift;
	my $rec    = shift;

	my $sql = "INSERT INTO itemlistfields (template_id, field_name, field_order) VALUES( ?, ?, ? )";
	my $sth = $dbh->prepare( $sql )  || return 0;
	return $sth->execute( $tmplid, $rec->{field_name}, $rec->{field_order} );
}


1;
