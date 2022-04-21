package lib::item;
use strict;

use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::time;
use dao::item;
use lib::property;
use lib::ip;
use lib::ipfunc;



#----- chkAuthDate -----------------------------------------------------------
# Check for an out-of-date auth last-check
# True if auth date is recent; False if prior to PERIOD.
sub chkAuthDate {
	my $last_check = shift;
	
	my $PERIOD = 1209600; # Two weeks
	
	my $cutoff_epoch = (lib::time::now_epoch() - $PERIOD);
	my $lastchk_epoch = lib::time::time_epoch( $last_check );

	# If date of last check is prior to PERIOD (ie. two weeks ago)
	if ($lastchk_epoch < $cutoff_epoch) {
		return 0;
	}
	
	return 1;
}




#----- appendItemAddr -------------------------------------------------------
# Append the addresses to the item_list hash.
# Arguments: $dbh, item_list is HoH of item records. 
# Returns the new HoH.
sub appendItemAddr {
	my $dbh      = shift;
	my $item_list = shift;

	my $list = dao::item::getItemAddrList( $dbh );
	if (!$list) {
		return $item_list;
	}
	
	foreach my $rec ( @{$list} ) {
		next if (!exists( $item_list->{$rec->{itemname}} ));
		
		$item_list->{$rec->{itemname}}->{"$rec->{iptype}_ID"} = $rec->{id};
		$item_list->{$rec->{itemname}}->{"$rec->{iptype}_COMMENT"} = $rec->{comment};
		if ($rec->{adminip}) {
			$item_list->{$rec->{itemname}}->{"$rec->{iptype}_ADMINIP"} = lib::ipfunc::int2ip( $rec->{ipaddr} );
		} else {
			$item_list->{$rec->{itemname}}->{"$rec->{iptype}_IPADDR"} = lib::ipfunc::int2ip( $rec->{ipaddr} );
		}
	}

	return $item_list;
}




#----- appendUsers -------------------------------------------------------
# Append the users to the item_list hash.
# Arguments: $dbh, item_list is HoH of item records. 
# Returns the new HoH.
sub appendUsers {
	my $dbh      = shift;
	my $item_list = shift;

	my %id;
	my %code;
	my %name;
	my $buf; 

	my $list = dao::item::getItemUserList( $dbh );
	if (!$list) {
		return $item_list;
	}

	foreach my $rec ( @{$list} ) {
		next if (!exists( $item_list->{$rec->{itemname}} ));
		
		# Create a hash by itemname to collect the user into lists.	
		$buf = $id{$rec->{itemname}};
		$buf .= $rec->{id} . ' - ';
		$id{$rec->{itemname}} = $buf;

		$buf = $code{$rec->{itemname}};
		$buf .= $rec->{code} . ' - ';
		$code{$rec->{itemname}} = $buf;

		$buf = $name{$rec->{itemname}};
		$buf .= $rec->{name} . ' - ';
		$name{$rec->{itemname}} = $buf;
	}

	# Insert the user lists into the item_list:
	foreach my $itemname (keys( %id )) {
		next if (!exists( $item_list->{$itemname} ));

		# Clean up the trailing " - " (3 chars = 3 chops)
		chop( $id{$itemname} );  chop( $id{$itemname} );  chop( $id{$itemname} );
		chop( $code{$itemname} );chop( $code{$itemname} );chop( $code{$itemname} );
		chop( $name{$itemname} );chop( $name{$itemname} );chop( $name{$itemname} );
	
		$item_list->{$itemname}->{userid}   = $id{$itemname};
		$item_list->{$itemname}->{usercode} = $code{$itemname};
		$item_list->{$itemname}->{username} = $name{$itemname};
	}

	return $item_list;
}




#----- appendItemProps -------------------------------------------------------
# Append the properties and their values to the item_list hash.
# Arguments: $dbh, item_list is HoH of item records. 
# Returns the new HoH.
sub appendItemProps {
	my $dbh      = shift;
	my $item_list = shift;

	my $list = dao::item::getItemPropList( $dbh );
	if ($list) {
		foreach my $rec ( @{$list} ) {
			next if (!exists( $item_list->{$rec->{itemname}} ));
			$item_list->{$rec->{itemname}}->{$rec->{name}} = $rec->{value};
		}
	}

	return $item_list;
}




#----- appendItemAttribs -------------------------------------------------------
# Append the attributes and their values to the item_list hash.
# Arguments: $dbh, item_list is HoH of item records. 
# Returns the new HoH.
sub appendItemAttribs {
	my $dbh      = shift;
	my $item_list = shift;

	my $list = dao::item::getItemAttribList( $dbh );
	if ($list) {
		foreach my $rec ( @{$list} ) {
			next if (!exists( $item_list->{$rec->{itemname}} ));
			$item_list->{$rec->{itemname}}->{$rec->{name}} = $rec->{value};
		}
	}

	return $item_list;
}




#----- appendItemFields -------------------------------------------------------
# Append the periphery fields (users, properties, attributes, addressing, etc)
# to the item_list data structure.
# Arguments: $dbh, item_list is HoH of item records. 
# Returns the new HoH.
sub appendItemFields {
	my $dbh      = shift;
	my $item_list = shift;

	$item_list = appendItemAddr(    $dbh, $item_list );
	$item_list = appendUsers(       $dbh, $item_list );
	$item_list = appendItemProps(   $dbh, $item_list );
	$item_list = appendItemAttribs( $dbh, $item_list );

	return $item_list;
}




#----- getItemList ---------------------------------------------------------
# Get a list of all items and all related fields from the periphery tables
# (properties, attribs, owners, users, ipaddr, etc.)
# Arguments: ($dbh)
# Returns: Hasg ref of hash refs (HoH) keyed by itemname.
sub getItemList {
	my $dbh = shift;

	my $item_list = dao::item::getItemList( $dbh );
	$item_list = appendItemFields( $dbh, $item_list );
	return $item_list;
}




#----- getItemListByType ---------------------------------------------------
sub getItemListByType {
	my $dbh    = shift;
	my $tmplid = shift;

	my $item_list = dao::item::getItemListByType( $dbh, $tmplid );
	$item_list = appendItemFields( $dbh, $item_list );
	return $item_list;
}




#----- getItem -------------------------------------------------------
# Get item record, includes the item fields as well as the 1:1 link
# fields for owner and template.  
# Arguments: ($dbh, $param)
# The argument $param contains the db field and value in an array. eg: (itemname, "v19u16") 
# Returns: Hash ref from fetchrow_hashref.
sub getItem {
	my $dbh   = shift;
	my $param = shift;

	# Get the basic item including the 1:1 fields of owner and template:
	my $item = dao::item::getItem( $dbh, $param );

	return $item;
}
	
	
	
	
#----- getItemId -------------------------------------------------------
# Get item id for the given itemname.
# Arguments: ($dbh, $itemname)
# Returns: Hash ref from fetchrow_hashref.
sub getItemId {
	my $dbh      = shift;
	my $itemname = shift;

	my $item_id = dao::item::getItemId( $dbh, $itemname );

	return $item_id;
}
	
	
	
	
#----- getItemReport -------------------------------------------------------
# Get a item by itemname, includes all periphery fields (prop, owner, 
# user, template, etc) in a flat, report format.
# Arguments: ($dbh, $itemname)
# Returns: Hash ref. of the type returned by fetchrow_hashref
sub getItemReport {
	my $dbh = shift;
	my $itemname = shift;

	# Get the basic item including the 1:1 fields of owner and template:
	my $item = dao::item::getItem( $dbh, ["itemname", $itemname] );

	# Append the properties as fields to the hash record. 
	my $list = dao::item::getItemProp( $dbh, $itemname );
	foreach my $key (keys( %{$list} )) {
		$item->{$list->{$key}->{name}} = $list->{$key}->{value};
	}

	# Append the addresses as fields to the hash record.
	# Format is iptype_field, eg. NAT_ID, NAT_COMMENT, PYSICAL_ID, etc.  
	$list = dao::item::getItemAddr( $dbh, $itemname );
	foreach my $key (keys( %{$list} )) {
		my $iptype = $list->{$key}->{iptype};
		$item->{$iptype . '_ID'} = $list->{$key}->{id};
		$item->{$iptype . '_COMMENT'} = $list->{$key}->{comment};
		if ($list->{$key}->{adminip}) {
			$item->{$iptype . '_ADMINIP'} = lib::ipfunc::int2ip( $list->{$key}->{ipaddr} );
		} else {
			$item->{$iptype . '_IPADDR'} = lib::ipfunc::int2ip( $list->{$key}->{ipaddr} );
		}
	}


	# Append the users as a pipe-delimited list in the corresponding fields "userid",
	# "usercode", and "username":
	$list = dao::item::getItemUsers( $dbh, $itemname );
	my $id;
	my $code;
	my $name;
	foreach my $key (sort keys( %{$list} )) {
		$id   .= $list->{$key}->{id} . '|';
		$code .= $list->{$key}->{code} . '|';
		$name .= $list->{$key}->{name} . '|';
	}

	chop( $id );
	chop( $code );
	chop( $name );

	$item->{userid}   = $id;
	$item->{usercode} = $code;
	$item->{username} = $name;

	return $item;
}




#----- getItemProps -------------------------------------------------------
# Get a list of the properties for this item. 
# Arguments: ($dbh, $itemname)
# Returns: Hash ref from fetchall_hashref with prop.name as the key.
sub getItemProps {
	my $dbh = shift;
	my $itemname = shift;

	return dao::item::getItemProps( $dbh, $itemname );
}
	
	

	
#----- getItemAttribs -------------------------------------------------------
# Get a list of the attribs (including values) for this item. 
# Arguments: ($dbh, $itemname)
# Returns: Hash ref from fetchall_hashref with prop.id as the key.
sub getItemAttribs {
	my $dbh       = shift;
	my $item_id = shift;

	return dao::item::getItemAttribs( $dbh, $item_id );
}
	
	

	
#----- getItemAddrs -------------------------------------------------------
# Get a list of the addr records for this item. 
# Arguments: ($dbh, $itemname)
# Returns: Hash ref from fetchall_hashref with id as the key.
sub getItemAddrs {
	my $dbh = shift;
	my $itemname = shift;

	my $list = dao::item::getItemAddrs( $dbh, $itemname );

	# Translate ip addresses into human-readable form. 
	foreach my $key (keys( %{$list} )) {
		$list->{$key}->{ipaddr} = lib::ipfunc::int2ip( $list->{$key}->{ipaddr} );
	}

	return $list;
}




#----- getItemUsers -------------------------------------------------------
# Get a list of the users for this item.
# Arguments: ($dbh, $itemname)
# Returns: Hash ref from fetchall_hashref with company.name as the key.
sub getItemUsers {
	my $dbh = shift;
	my $itemname = shift;

	return dao::item::getItemUsers( $dbh, $itemname );
}
	
	

	
#----- updateItemById ------------------------------------------------------
sub updateItem {
	my $dbh = shift;
	my $rec = shift;
	return dao::item::updateItem( $dbh, $rec );
}



#----- updateItemTemplate ------------------------------------------------------
# Update the template_id field and remove any propitemlink records that are no
# longer relevant to the new relationship.
sub updateItemTemplate {
	my $dbh    = shift;
	my $id     = shift;
	my $tmplid = shift;

	return dao::item::updateItemTemplate( $dbh, $id, $tmplid );
}



#----- setOwner -------------------------------------------------------
# Set the company(id) for this item(id) in the ownerlink table.  
# Arguments: ($dbh, $item_id, company_id)
# Returns: nothing.
sub setOwner {
	my $dbh = shift;
	my $item_id = shift;
	my $company_id = shift;

	return dao::item::setOwner( $dbh, $item_id, $company_id );
}



#----- setUsers -------------------------------------------------------
# Set the company(id) for this item(id) in the userlink table for each
# item in the $users arrayref.  
# Arguments: ($dbh, $item_id, $users)
# Returns: nothing.
sub setUsers {
	my $dbh         = shift;
	my $item_id   = shift;
	my $company_ids = shift;

	foreach my $company_id (@$company_ids) {
		dao::item::setUser( $dbh, $item_id, $company_id ) || return 0;
	}
	
	return 1;
}




#----- clearProperty -------------------------------------------------------
# Clear the specified record from the propitemlink table. 
# Arguments: ($dbh, $item_id, $prop_id, $propval_id)
# Returns: nothing.
sub clearProperty {
	my $dbh        = shift;
	my $item_id  = shift;
	my $prop_id    = shift;
	my $propval_id = shift;

	return dao::item::clearProperty( $dbh, $item_id, $prop_id, $propval_id );
}




#----- clearProperties -------------------------------------------------------
# Clear the propitemlink table for the specified item. 
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearProperties {
	my $dbh        = shift;
	my $item_id  = shift;

	return dao::item::clearProperties( $dbh, $item_id ) || return 0;
}




#----- clearAttribs -------------------------------------------------------
# Clear the attribval table for the specified item. 
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearAttribs {
	my $dbh        = shift;
	my $item_id  = shift;

	return dao::item::clearAttribs( $dbh, $item_id ) || return 0;
}




#----- clearOwner -------------------------------------------------------
# Clear the ownerlink records for the specified item.
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearOwner {
	my $dbh        = shift;
	my $item_id  = shift;

	return dao::item::clearOwner( $dbh, $item_id ) || return 0;
}




#----- clearUsers -------------------------------------------------------
# Clear the userlink records for the specified item.
# Arguments: ($dbh, $item_id)
# Returns: boolean.
sub clearUsers {
	my $dbh        = shift;
	my $item_id  = shift;

	return dao::item::clearUsers( $dbh, $item_id ) || return 0;
}




#----- setProperty -------------------------------------------------------
# Set the prop(id) and propval(id) for this item(id) in the propitemlink table
# Arguments: ($dbh, $item_id, $prop_id, $propval_id)
# Returns: nothing.
sub setProperty {
	my $dbh        = shift;
	my $item_id  = shift;
	my $prop_id    = shift;
	my $propval_id = shift;

	return dao::item::setProperty( $dbh, $item_id, $prop_id, $propval_id );
}




#----- setAttribute -------------------------------------------------------
# Returns: The attribval(id) on success, or boolean 0 on failure.
sub setAttribute {
	my $dbh       = shift;
	my $item_id = shift;
	my $prop_id   = shift;
	my $value     = shift;

	return dao::item::setAttribute( $dbh, $item_id, $prop_id, $value );
}




#----- addItem ------------------------------------------------------
sub addItem {
	my $dbh = shift;
	my $rec = shift;
	
	return dao::item::addItem( $dbh, $rec );
}




#----- delItemById ---------------------------------------------------
sub delItemById {
	my $dbh = shift;
	my $item_id = shift;

	dao::item::clearOwner( $dbh, $item_id )      || return 0;
	dao::item::clearUsers( $dbh, $item_id )      || return 0;
	dao::item::clearProperties( $dbh, $item_id ) || return 0;
	dao::item::clearAttribs( $dbh, $item_id )    || return 0;

	return dao::item::delItem( $dbh, ["id", $item_id] );
}



1;
