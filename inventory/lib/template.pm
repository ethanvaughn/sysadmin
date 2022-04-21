package lib::template;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::template;





#----- getFieldList ------------------------------------------------------------------
# Get a list of possible fields for the main screen.
# Returns HoHref keyed by fieldname.
sub getFieldList {
	my $dbh    = shift;
	my $tmplid = shift;

	my $fields;

	# Fields available from the item schema:
	$fields->{itemname}   = { 'field_name' => "itemname",   'field_label' => "Item Name" };
	$fields->{serialno}   = { 'field_name' => "serialno",   'field_label' => "Serial Num" };
	$fields->{comment}    = { 'field_name' => "comment",    'field_label' => "Comment" };
	$fields->{auth_check} = { 'field_name' => "auth_check", 'field_label' => "Auth" };
	$fields->{adminip}    = { 'field_name' => "adminip",    'field_label' => "Admin IP" };
	
	# Owner and Users
	$fields->{ownername} = { 'field_name' => "ownername", 'field_label' => "Owner" };

	if (dao::template::useFieldUsers( $dbh, $tmplid )) {
		$fields->{username}   = { 'field_name' => "username", 'field_label' => "Users" };
	}


	# Properties
	my $tmpl_prop_list = getTemplatePropList( $dbh, $tmplid );
	www::cgi::helpers::chkDB( $dbh );

	foreach my $name (sort keys( %{$tmpl_prop_list} )) {
		$fields->{$name} = { 'field_name' => $name, 'field_label' => $name };
	}

	return $fields;
}




#----- getTemplateFieldList ------------------------------------------------------------------
# Get a list fields to show on the main screen for this template.
# Returns HoHref keyed by fieldname.
sub getTemplateFieldList {
	my $dbh    = shift;
	my $tmplid = shift;
	return dao::template::getTemplateFieldList( $dbh, $tmplid );
}




#----- getTemplateList ---------------------------------------------------------
# Get a list of all templates. 
# Arguments: None.
# Returns: Standard fetchall_hashref
sub getTemplateList {
	my $dbh = shift;
	return dao::template::getTemplateList( $dbh );
}




#----- getTemplateDropdown ---------------------------------------------------------
# Get a <select> dropdown component for selecting templates. 
# Arguments: ($onchange, $vars, $list)
#    $onchange = Javascript function to call.
#    $vars     = The Get/Post vars from the controller.
#    $list     = The list of template records from the db.
#    $useAll   = Bool. If true, present the "ALL" option. Otherwise present "Select Template"
# Returns: Standard fetchall_hashref
sub getTemplateDropdown {
	my $onchange  = shift;
	my $vars      = shift;
	my $list      = shift;
	my $useAll    = shift;
	
	# Assemble the main template <select> drop-down: 	
	my $select_tmpl = qq|\n<select tabindex=1 id="select_tmpl" name="tmplid" onchange="$onchange">\n|;

	if ($useAll) {
		$select_tmpl .= qq|<option selected value="0">LIST ALL</option>|;
	} else {
		$select_tmpl .= qq|<option selected value="0">-- Select Template --</option>| if (!$vars->{tmplid});
	}
	
	foreach my $tmplname (sort keys( %{$list} )) {
		$select_tmpl .= qq|<option id="select_tmpl$list->{$tmplname}->{id}" |;
		$select_tmpl .= qq|value="$list->{$tmplname}->{id}" |;
		if ($vars->{tmplid} && $vars->{tmplid} eq $list->{$tmplname}->{id}) {
			$select_tmpl .= qq|selected |;
			$vars->{tmplname} = $list->{$tmplname}->{name};
		}
		$select_tmpl .= qq|>$list->{$tmplname}->{name}</option>\n|;
	}
	$select_tmpl .= qq|</select>\n|;

	return $select_tmpl;
}




#----- getTemplatePropList --------------------------------------------------------- 
# Get a list of properties for a given template id. 
# Returns: Standard fetchall_hashref
sub getTemplatePropList {
	my $dbh    = shift;
	my $tmplid = shift;
	
 	return dao::template::getTemplatePropList( $dbh, $tmplid );
}




#----- useFieldUsers --------------------------------------------------------- 
# Determine if the Users field is assigned to this template.
# Returns: boolean
sub useFieldUsers {
	my $dbh    = shift;
	my $tmplid = shift;
	return dao::template::useFieldUsers( $dbh, $tmplid );
}
	



#----- getTemplateById ---------------------------------------------------------
# Get details for a single template. 
# Arguments: ($dbh, $id)
# Returns: Hash ref.
sub getTemplateById {
	my $dbh = shift;
	my $id = shift;
	return dao::template::getTemplate( $dbh, ["id", $id] );
}




#----- getTemplateByName -------------------------------------------------------
# Get details for a single template. 
# Arguments: ($dbh, $name)
# Returns: Hash ref.
sub getTemplateByName {
	my $dbh = shift;
	my $name = shift;
	return dao::template::getTemplate( $dbh, ["name", $name] );
}




#----- updateTemplate ------------------------------------------------------
sub updateTemplate {
	my $dbh = shift;
	my $rec = shift;
	return dao::template::updateTemplate( $dbh, $rec );
}




#----- addTemplate ------------------------------------------------------
sub addTemplate {
	my $dbh = shift;
	my $rec = shift;

	dao::template::addTemplate( $dbh, $rec ) || return 0;
	
	# Return the new record's id
	return dao::template::getTemplateId( $dbh, $rec->{tmplname} );
}




#----- delTemplateById ---------------------------------------------------
sub delTemplateById {
	my $dbh = shift;
	my $id = shift;
	return dao::template::delTemplate( $dbh, ["id", $id] );
}




#----- clearUserLink ---------------------------------------------------
# Clear this tmplid from the usertemplatelink table.
sub clearUserLink {
	my $dbh    = shift;
	my $tmplid = shift;
	return dao::template::clearUserLink( $dbh, $tmplid );
}




#----- setUserLink ---------------------------------------------------
# Write this tmplid to the usertemplatelink table.
sub setUserLink {
	my $dbh    = shift;
	my $tmplid = shift;
	return dao::template::setUserLink( $dbh, $tmplid );
}




#----- setPropLinks ---------------------------------------------------
# Set the template->property links for the given template id and 
# array of property ids.
# Returns: nothing. 
sub setPropLinks {
print STDERR "setPropLinks ... \n";
	my $dbh     = shift;
	my $tmplid  = shift;
	my $propids = shift;

	# Remove all links:
	dao::template::clearPropLinks( $dbh, $tmplid ) || return 0;

	# Insert a link for each template id.
	foreach $propid (@{$propids}) {
		dao::template::setPropLink( $dbh, $tmplid, $propid ) || return 0;
	}
	
	return 1;
}




#----- clearTemplateFields ---------------------------------------------------
# Clear records of this tmplid from the itemlistfields table.
sub clearTemplateFields {
print STDERR "clearTemplateFields ... \n";
	my $dbh    = shift;
	my $tmplid = shift;
	return dao::template::clearTemplateFields( $dbh, $tmplid );
}




#----- setTemplateFields ---------------------------------------------------
# Write this tmplid to the itemlistfields table for each fieldname.
sub setTemplateFields {
print STDERR "setTemplateFields ... \n";
	my $dbh     = shift;
	my $tmplid  = shift;
	my $fields  = shift;

	# Remove all links:
	clearTemplateFields( $dbh, $tmplid ) || return 0;

	# Insert a link for each template id.
	foreach my $rec (@{$fields}) {
		dao::template::setTemplateField( $dbh, $tmplid, $rec ) || return 0;
	}
	
	return 1;
}






1;
