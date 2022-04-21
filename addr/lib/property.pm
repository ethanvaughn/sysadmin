package lib::property;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::property;


#----- getPropList --------------------------------------------------------
# Get a list of all properties. 
# Arguments: ($dbh)
# Returns: Hash ref of hash refs (HoH) keyed by property name.
sub getPropList {
	my $dbh = shift;
	return dao::property::getPropList( $dbh );
}




#----- getPropValues --------------------------------------------------------
# Get a list of property values for the given property.
# Arguments: ($dbh, $prop_id)
# Returns: fetchall_hashref keyed by "value"
sub getPropValues {
	my $dbh = shift;
	my $prop_id = shift;
	return dao::property::getPropValues( $dbh, $prop_id );
}




#----- getPropertyById ---------------------------------------------------------
# Get details for a single property. 
# Arguments: ($dbh, $id)
# Returns: Hash ref.
sub getPropertyById {
	my $dbh = shift;
	my $id = shift;
	return dao::property::getPropertyById( $dbh, $id );
}




#----- getPropertyByName -------------------------------------------------------
# Get details for a single property. 
# Arguments: ($dbh, $name)
# Returns: Hash ref.
sub getPropertyByName {
	my $dbh = shift;
	my $name = shift;
	my $value = shift;
	return dao::property::getPropertyByName( $dbh, $name, $value );
}




#----- getPropTemplateList ---------------------------------------------------------------
# Get a list of templates for a given property id. 
# Arguments: None.
# Returns: Standard fetchall_hashref
sub getPropTemplateList {
	my $dbh    = shift;
	my $prop_id = shift;
	return dao::property::getPropTemplateList( $dbh, $prop_id );
}





#----- updateProperty ------------------------------------------------------
sub updateProperty {
	my $dbh = shift;
	my $rec = shift;
	return dao::property::updateProperty( $dbh, $rec );
}




#----- addProperty ------------------------------------------------------
sub addProperty {
	my $dbh = shift;
	my $rec = shift;

	dao::property::addProperty( $dbh, $rec ) || return 0;
	# Return the new record's id
	return dao::property::getPropId( $dbh, $rec->{propname} );
}




#----- delPropertyById ---------------------------------------------------
sub delPropertyById {
	my $dbh = shift;
	my $id = shift;
	return dao::property::delProperty( $dbh, ["id", $id] );
}



#----- updatePropVal ------------------------------------------------------
sub updatePropVal {
	my $dbh = shift;
	my $rec = shift;
	return dao::property::updatePropVal( $dbh, $rec );
}



#----- addPropVal ------------------------------------------------------
sub addPropVal {
	my $dbh = shift;
	my $rec = shift;

	dao::property::addPropVal( $dbh, $rec ) || return 0;
	
	# Return the new record's id
	return dao::property::getPropValId( $dbh, $rec->{prop_id}, $rec->{propval} );
}


#----- delPropVal ---------------------------------------------------
sub delPropVal {
	my $dbh = shift;
	my $id = shift;
	return dao::property::delPropVal( $dbh, $id );
}




#----- setTmplLinks ---------------------------------------------------
# Set the template->property links for the given prop id and 
# array of template ids.
# Returns: nothing. 
sub setTmplLinks {
	my $dbh     = shift;
	my $prop_id  = shift;
	my $tmplids = shift;

	# Remove all links:
	dao::property::clearTmplLinks( $dbh, $prop_id ) || return 0;

	# Insert a link for each template id.
	foreach $tmplid (@{$tmplids}) {
		dao::property::setTmplLink( $dbh, $prop_id, $tmplid ) || return 0;
	}
	
	return 1;
}


1;
