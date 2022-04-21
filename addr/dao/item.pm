package dao::item;

use lib::time;

use strict;




#-----
# Return the base SQL join for an item list.
sub getItemListSQL {
	my $sql = <<SQL;
	SELECT  
		item.id,
		item.itemname,
		item.serialno,
		item.comment,
		item.auth_check,
		item.admin_notes,
		item.notes,
		template.id as templateid,
		template.name as template,
		company.id as ownerid,
		company.code as ownercode,
		company.name as ownername	
	FROM item,ownerlink,company,template
	WHERE item.id = ownerlink.item_id
	AND company.id = ownerlink.company_id
	AND item.template_id = template.id
SQL

	return $sql;
}




#----- getItemList -----------------------------------------------------------------
sub getItemList {
	my $dbh    = shift;
	
	my $sql = getItemListSQL();

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;
	my $rec = $sth->fetchall_hashref( 'itemname' );
	$sth->finish;
	
	return $rec;
}




#----- getItemListByType -----------------------------------------------------------------
sub getItemListByType {
	my $dbh    = shift;
	my $tmplid = shift;
	
	my $sql = getItemListSQL();
	$sql .= " AND template.id = ?";

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $tmplid )               || return 0;
	my $rec = $sth->fetchall_hashref( 'itemname' );
	$sth->finish;
	
	return $rec;
}




#----- getItemPropList -----------------------------------------------------------------
sub getItemPropList {
	my $dbh    = shift;

	my $sql = <<SQL;
	SELECT
		item.itemname,
		prop.name,
		prop.type,
		propval.value
	FROM item,prop,propval,propitemlink
	WHERE item.id = propitemlink.item_id
	AND propitemlink.prop_id = prop.id
	AND propitemlink.propval_id = propval.id
	AND prop.type = 'PROP'
	ORDER BY item.itemname,prop.name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my @data;
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	$sth->finish;

	return \@data;
}




#----- getItemAttribList -----------------------------------------------------------------
sub getItemAttribList {
	my $dbh    = shift;

	my $sql = <<SQL;
	SELECT
		item.itemname,
		prop.name,
		prop.type,
		attribval.value
	FROM item,prop,attribval
	WHERE item.id = attribval.item_id
	AND attribval.prop_id = prop.id
	ORDER BY item.itemname,prop.name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my @data;
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	$sth->finish;

	return \@data;
}




#----- getItemAddrList -----------------------------------------------------------------
sub getItemAddrList {
	my $dbh = shift;

	my $sql = <<SQL;
	SELECT
		item.itemname,
		ipaddr.id,
		ipaddr.ipaddr,
		ipaddr.adminip,
		ipaddr.comment as ipcomment,
		iptype.name as iptype
	FROM item,ipaddr,iptypelink,iptype
	WHERE item.id = ipaddr.item_id
	AND iptypelink.ipaddr_id = ipaddr.id
	AND iptypelink.iptype_id = iptype.id
	ORDER BY item.itemname,iptype.name;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my @data;
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	$sth->finish;

	return \@data;
}




#----- getItemUserList -----------------------------------------------------------------
sub getItemUserList {
	my $dbh    = shift;

	my $sql = <<SQL;
	SELECT  
		item.itemname,
		company.id,
		company.code,
		company.name	
	FROM item,userlink,company
	WHERE item.id = userlink.item_id
	AND company.id = userlink.company_id
	ORDER BY itemname;
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute()                        || return 0;

	my @data;
	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}
	$sth->finish;
	
	return \@data;
}




#----- getItemId ---------------------------------------------------------------
# Get id for the given itemname
# Arguments: ($dbh, $itemname)
# Returns: int item id.
sub getItemId {
	my $dbh      = shift;
	my $itemname = shift;

	my $sql = "SELECT id FROM item WHERE itemname = ?";

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $itemname )             || return 0;
	my $data = $sth->fetchrow_hashref()    || return 0;
	$sth->finish;
	
	return $data->{id};
}




#----- getItem ---------------------------------------------------------------
# Get detail for a single item.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (itemname, "v19u16") 
# Returns: hashref of the item record.
sub getItem {
	my $dbh = shift;
	my $param = shift;

	my $sql = <<SQL;
	SELECT  
		item.id,
		item.itemname,
		item.serialno,
		item.comment,
		item.auth_check,
		item.admin_notes,
		item.notes,
		template.id as tmplid,
		template.name as tmplname,
		company.id as ownerid,
		company.code as ownercode,
		company.name as ownername	
	FROM item,ownerlink,company,template
	WHERE item.id = ownerlink.item_id
	AND company.id = ownerlink.company_id
	AND item.template_id = template.id
	AND item.$param->[0] = ?
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $param->[1] )           || return 0;
	my $data = $sth->fetchrow_hashref()    || return 0;
	$sth->finish;
	
	return $data;
}




#----- getItemProps -----------------------------------------------------------------
sub getItemProps {
	my $dbh      = shift;
	my $itemname = shift;

	my $sql = <<SQL;
	SELECT
		prop.name,
		prop.type,
		propval.value
	FROM item,prop,propval,propitemlink
	WHERE item.id = propitemlink.item_id
	AND propitemlink.prop_id = prop.id
	AND propitemlink.propval_id = propval.id
	AND item.itemname = ?
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $itemname )             || return 0;
	my $data = $sth->fetchall_hashref( 'name' );
	$sth->finish;

	return $data;
}




#----- getItemAttribs -----------------------------------------------------------------
sub getItemAttribs {
	my $dbh       = shift;
	my $item_id = shift;

	my $sql = "SELECT id,item_id,prop_id,value FROM attribval WHERE item_id = ?";

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $item_id )            || return 0;
	my $data = $sth->fetchall_hashref( 'prop_id' );
	$sth->finish;

	return $data;
}




#----- getItemAddrs -----------------------------------------------------------------
sub getItemAddrs {
	my $dbh      = shift;
	my $itemname = shift;

	my $sql = <<SQL;
	SELECT
		ipaddr.id,
		ipaddr.ipaddr,
		ipaddr.adminip,
		ipaddr.comment,
		iptype.name as iptype
	FROM item,ipaddr,iptypelink,iptype
	WHERE item.id = ipaddr.item_id
	AND iptypelink.ipaddr_id = ipaddr.id
	AND iptypelink.iptype_id = iptype.id
	AND item.itemname = ?
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $itemname )             || return 0;
	my $data = $sth->fetchall_hashref( 'id' );
	$sth->finish;

	return $data;
}




#----- getItemUsers -----------------------------------------------------------------
# Get a list of users for a specific item. 
# Returns standard fetchall_hashref indexed by name.
sub getItemUsers {
	my $dbh      = shift;
	my $itemname = shift;

	my $sql = <<SQL;
	SELECT  
		company.id,
		company.code,
		company.name	
	FROM item,userlink,company
	WHERE item.id = userlink.item_id
	AND company.id = userlink.company_id
	AND item.itemname = ?
SQL

	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	$sth->execute( $itemname )             || return 0;

	my $data = $sth->fetchall_hashref( 'name' );
	$sth->finish;

	return $data;
}




#----- addItem ----------------------------------------------------------------
# Insert new item into the "item" table. 
# Returns: Nothing.
sub addItem {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		INSERT INTO item (
			itemname,
			serialno,
			comment,
			template_id,
			admin_notes,
			notes,
			ctime
		)
	VALUES ( ?,?,?,?,?,?,'NOW()' )
SQL
	my $sth = $dbh->prepare_cached( $sql ) || return 0;
	return $sth->execute( 
		$rec->{itemname},
		$rec->{serialno},
		$rec->{comment},
		$rec->{tmplid},
		$rec->{admin_notes},
		$rec->{notes}
	);
}




#----- updateItem ----------------------------------------------------------------
# Returns: Nothing.
sub updateItem {
	my $dbh = shift;
	my $rec = shift;

	my $sql = <<SQL;
		UPDATE item SET
		itemname    = '$rec->{itemname}',
		serialno    = '$rec->{serialno}',
		comment     = '$rec->{comment}',
		admin_notes = '$rec->{admin_notes}',
		notes       = '$rec->{notes}',
		mtime       = 'NOW()'
		WHERE id    = '$rec->{id}'
SQL

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute();
}




#----- updateItem Template ----------------------------------------------------------------
# Update the template_id field.
sub updateItemTemplate {
	my $dbh    = shift;
	my $id     = shift;
	my $tmplid = shift;

	my $sql = "UPDATE item SET template_id = ? WHERE id = ?";

	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $tmplid, $id );
}




#----- setOwner -------------------------------------------------------
# Set the company(id) for this item(id) in the ownerlink table.  
# Arguments: ($dbh, $item_id, company_id)
# Returns: nothing.
sub setOwner {
	my $dbh = shift;
	my $item_id = shift;
	my $company_id = shift;

	# First clean up any references to this item in the ownerlink table:
	clearOwner( $dbh, $item_id ) || return 0;
	
	my $sql = "INSERT INTO ownerlink (item_id, company_id) VALUES( ?, ? )";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id, $company_id );
}




#----- clearOnwer -------------------------------------------------------
# Clear all company(id) for this item(id) in the ownerlink table.  
# Arguments: ($dbh, $item_id)
# Returns: nothing.
sub clearOwner {
	my $dbh = shift;
	my $item_id = shift;

	my $sql = "DELETE FROM ownerlink WHERE item_id=?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id );
}




#----- clearUsers -------------------------------------------------------
# Clear all company(id) for this item(id) in the userlink table.  
# Arguments: ($dbh, $item_id)
# Returns: nothing.
sub clearUsers {
	my $dbh = shift;
	my $item_id = shift;

	my $sql = "DELETE FROM userlink WHERE item_id=?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id );
}



#----- clearProperty -------------------------------------------------------
# Remove the specified record from the propitemlink table.  
# Arguments: ($dbh, $item_id, prop_id, propval_id)
# Returns: boolean.
sub clearProperty {
	my $dbh       = shift;
	my $item_id = shift;
	my $prop_id = shift;
	my $propval_id = shift;

	my $sql = "DELETE FROM propitemlink WHERE item_id=? AND prop_id=? AND propval_id=?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id, $prop_id, $propval_id );
}




#----- clearProperties -------------------------------------------------------
# Clear all records for this item(id) in the propitemlink table.  
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearProperties {
	my $dbh       = shift;
	my $item_id = shift;

	my $sql = "DELETE FROM propitemlink WHERE item_id=?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id );
}




#----- clearAttribs -------------------------------------------------------
# Clear all records for this item(id) in the attribval table.  
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearAttribs {
	my $dbh       = shift;
	my $item_id = shift;

	my $sql = "DELETE FROM attribval WHERE item_id=?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id );
}




#----- setUser -------------------------------------------------------
# Set the company(id) for this item(id) in the userlink table.  
# Arguments: ($dbh, $item_id, company_id)
# Returns: boolean.
sub setUser {
	my $dbh = shift;
	my $item_id = shift;
	my $company_id = shift;

	my $sql = "INSERT INTO userlink (item_id, company_id) VALUES(?,?)";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id, $company_id );
}




#----- setProperty -------------------------------------------------------
# Create a propitemlink record for this item(id).
# Arguments: ($dbh, $item_id, prop_id, propval_id)
# Returns: nothing.
sub setProperty {
	my $dbh = shift;
	my $item_id = shift;
	my $prop_id = shift;
	my $propval_id = shift;

	my $sql = "INSERT INTO propitemlink (item_id, prop_id, propval_id) VALUES(?,?,?)";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $item_id, $prop_id, $propval_id );
}




#----- updateAttribute -------------------------------------------------------
# Update the value of the attribute for a given prop_id and propval_id. 
# Arguments: ($dbh, prop_id, propval_id, value)
# Returns: nothing.
sub updateAttribute {
	my $dbh        = shift;
	my $prop_id    = shift;
	my $propval_id = shift;
	my $value      = shift;

	my $sql = "UPDATE propval SET value=? WHERE prop_id=? AND id=?";
	my $sth = $dbh->prepare( $sql )   || return 0;
	$sth->execute( $value, $prop_id, $propval_id  ) || return 0;
	$sth->finish;
	return 1;
}




#----- setAttribute -------------------------------------------------------
# 1. Create the propval record. 2. Create the propitemlink record.
# Arguments: ($dbh, $item_id, prop_id, value)
# Returns: nothing.
sub setAttribute {
	my $dbh       = shift;
	my $item_id   = shift;
	my $prop_id   = shift;
	my $value     = shift;

	# Create the attribval record: 
	my $sql = "INSERT INTO attribval (item_id, prop_id, value) VALUES( ?, ?, ? )";
	my $sth = $dbh->prepare( $sql )   || return 0;
	$sth->execute( $item_id, $prop_id, $value ) || return 0;
	$sth->finish;

	
	# Get the id of the newly created propval record:
	$sql = "SELECT id FROM attribval WHERE item_id=? AND prop_id=?";
	$sth = $dbh->prepare( $sql )      || return 0;
	$sth->execute( $item_id, $prop_id ) || return 0;
	my $data = $sth->fetchrow_hashref();
	$sth->finish;
	
	return $data->{id};
}




#----- delItem ----------------------------------------------------------------
# Delete a single item.
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (itemname, "v19u16") 
# Returns: nothing.
sub delItem {
	my $dbh = shift;
	my $param = shift;

	my $sql = "DELETE FROM item WHERE $param->[0] = ?";
	my $sth = $dbh->prepare( $sql ) || return 0;
	return $sth->execute( $param->[1] );
}




1;