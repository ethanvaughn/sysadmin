#!/usr/bin/perl

# This script converts the device -> property values from the v1_0_8 to the v1_0_9
# 
# Conversion Steps:

# 1.  Run pg_dump -U postgres -C ops -f ops.dump.sql (see DUMP-EXAMPLE.txt)
#
# 
# 2.  Create the new tables: template, prop, propval, propdevicelink, proptemplatelink, attribval
# 
# 
# 3.  Run delta-1_0_9-1create.sql
# 
# 
# 4.  Run this conversion script (convert_108-201.pl)
#
#        ./convert_108-201.pl &> convert.log
# 
# 
# 5.  Validate by spot-checking using the following SQL:
#
#         select pl.device_id,p.name,p.value
#         from proplink as pl,property as p
#         where pl.device_id=100069
#         and pl.property_id = p.id
#         order by p.name;
#         select device.id,prop.name,propval.value 
#         from device,prop,propval,propdevicelink
#         where device_id = 100069
#         and device.id=propdevicelink.device_id
#         and prop.id=propdevicelink.prop_id
#         and propval.id=propdevicelink.propval_id
#         order by prop.name;
# 
#  *Note that the "TYPE" property will be dropped in the v2_0_1 and 
#  should be missing in the comparison.
#
#
#
# 6.  Run delta-1_0_9-2cleanup.sql
# 
# 




# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use dao::device;
use lib::device;
use lib::company;
use lib::property;

use strict;




#----- clearLink -----------------------------------------------------------------
sub clearLink {
	my $dbh     = shift;

	my $sql = "DELETE FROM proptemplatelink";

	my $cnt = $dbh->do( $sql )
		or die "Couldn't execute statement: " . $dbh->errstr;

	my $sql = "DELETE FROM propdevicelink";

	my $cnt = $dbh->do( $sql )
		or die "Couldn't execute statement: " . $dbh->errstr;
}




#----- getPropertyRecs -----------------------------------------------------------------
sub getPropertyRecs {
	my $dbh    = shift;
	my $dev_id = shift;
	
	my @data;
	
	my $sql = <<SQL;
		select pl.device_id,pl.property_id,p.name,p.value
		from proplink as pl,property as p
		where pl.device_id=?
		and pl.property_id = p.id;
SQL

	my $sth = $dbh->prepare_cached( $sql )
			or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute( $dev_id )
		or die "Couldn't execute statement: " . $dbh->errstr;

	while (my $row = $sth->fetchrow_hashref()) {
		push( @data, $row );
	}

	return \@data;
}




#----- getPropId -----------------------------------------------------------------
sub getPropId {
	my $dbh  = shift;
	my $name = shift;

	my $sql = <<SQL;
		select id
		from prop
		where name = ?
SQL

	my $sth = $dbh->prepare( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute( $name )
		or die "Couldn't execute statement: " . $dbh->errstr;

	my ($id) = $sth->fetchrow_array();
	return $id;
}




#----- addProp -----------------------------------------------------------------
sub addProp {
	my $dbh  = shift;
	my $name = shift;

	my $sql = "INSERT INTO prop (name, ctime) VALUES (?, 'NOW()')";

	my $sth = $dbh->prepare_cached( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;
		
	$sth->execute( $name )
		or die "Couldn't execute statement: " . $dbh->errstr;
}



#----- getPropvalId -----------------------------------------------------------------
sub getPropvalId {
	my $dbh      = shift;
	my $prop_id  = shift;
	my $value    = shift;

	my $sql = "select id from propval where prop_id = ? and value = ?";

	my $sth = $dbh->prepare( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute( $prop_id, $value )
		or die "Couldn't execute statement: " . $dbh->errstr;

	my ($id) = $sth->fetchrow_array();
	return $id;
}




#----- addPropval -----------------------------------------------------------------
sub addPropval {
	my $dbh     = shift;
	my $prop_id = shift;
	my $value   = shift;

	my $sql = "INSERT INTO propval (prop_id, value, ctime) VALUES (?, ?, 'NOW()')";

	my $sth = $dbh->prepare_cached( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;
		
	$sth->execute( $prop_id, $value );
#		or die "Couldn't execute statement: " . $dbh->errstr;
}





#----- addProplink -----------------------------------------------------------------
sub addProplink {
	my $dbh        = shift;
	my $prop_id    = shift;
	my $propval_id = shift;
	my $dev_id     = shift;

	my $sql = "INSERT INTO propdevicelink (prop_id, propval_id, device_id) VALUES (?, ?, ?)";

	my $sth = $dbh->prepare_cached( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;
		
	$sth->execute( $prop_id, $propval_id, $dev_id )
		or die "Couldn't execute statement: " . $dbh->errstr;
}




#----- addPropTlink -----------------------------------------------------------------
sub addPropTlink {
	my $dbh     = shift;
	my $prop_id = shift;

	my $sql = "INSERT INTO proptemplatelink (prop_id, template_id) VALUES (?, 1)";

	my $sth = $dbh->prepare_cached( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;
		
	$sth->execute( $prop_id );
}




#----- getTLinkId -----------------------------------------------------------------
sub getTLinkId {
	my $dbh      = shift;
	my $prop_id  = shift;
	my $templ_id = shift;

	my $sql = "select $templ_id as id from proptemplatelink where prop_id = ? and template_id = ?";

	my $sth = $dbh->prepare( $sql )
		or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute( $prop_id, $templ_id )
		or die "Couldn't execute statement: " . $dbh->errstr;

	my ($id) = $sth->fetchrow_array();
	return $id;
}




#----- getDevCnt -----------------------------------------------------------------
sub getDevCnt {
	my $dbh  = shift;

	my $sth = $dbh->prepare( "select count(id) from device" )
		or die "Couldn't prepare statement: " . $dbh->errstr;

	$sth->execute()
		or die "Couldn't execute statement: " . $dbh->errstr;

	my ($count) = $sth->fetchrow_array();
	return $count;
}




#----- Main ------------------------------------------------------------------

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $prop_id = 0;
my $propval_id = 0;
my $tlink_id = 0;

clearLink( $dbh );
print "Cleared proptemplatelink and propdevicelink tables.\n";
my $curdevcnt = getDevCnt( $dbh );

my $devlist = dao::device::getDeviceList( $dbh );
my $devcnt = 0;
#foreach my $rec (@$devlist) {
foreach my $hostname (sort keys( %$devlist )) {
	$devcnt++;
	my $dev_id = $dev_list->{$hostname}->{id};
#	print "\n[$rec->{id}  $rec->{hostname}]\n";
	print "\n[$dev_id  $hostname]\n";
	my $proplist = getPropertyRecs( $dbh, $id );

	foreach my $proprec (@$proplist) {
		if ($proprec->{name} eq 'TYPE') {
			next;
		}

		print "    [$proprec->{device_id}  $proprec->{property_id}  $proprec->{name}  $proprec->{value}] \n";

		# Add the property name
		$prop_id = getPropId( $dbh, $proprec->{name} );
		if ($prop_id == 0) {
			print "         [prop]           : $proprec->{name} \n";
			addProp( $dbh, $proprec->{name} );
			$prop_id = getPropId( $dbh, $proprec->{name} );
		}

		# Add the value
		$propval_id = getPropvalId( $dbh, $prop_id, $proprec->{value} );
		if ($propval_id == 0) {
			print "         [propval]        : $prop_id, $proprec->{value} \n";
			addPropval( $dbh, $prop_id, $proprec->{value} );
			$propval_id = getPropvalId( $dbh, $prop_id, $proprec->{value} );
		}

		# Link this property to device. 
		print "         [propdevicelink] : $prop_id, $propval_id, $dev_id \n";
		addProplink( $dbh, $prop_id, $propval_id, $dev_id );

		# Link this property to the HOSTED_SERVER template (id=1)
		$tlink_id = getTLinkId( $dbh, $prop_id, 1 );
		if ($tlink_id == 0) {
			print "         [propTlink]      : $prop_id, 1 \n";
			addPropTlink( $dbh, $prop_id );
		}
	}
}

$dbh->commit;
dao::saconnect::disconnect( $dbh );

print "\nTotal Device in DB   : [$curdevcnt]\n";
print "Total Devices Converted: [$devcnt]\n";

exit (0);
