#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::saconnect;
use lib::time;

use strict;


#----- GLOBALS ---------------------------------------------------------------
my @fields;
my $fieldlist;
my $field_placeholders;
my $insert_query;
my $sth;
my @data_loh;

my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";


#----- insert -------------------------------------------------------------
# Arguments: ( table ) -- uses globals @fields, @data_loh (fix it) 
# Returns: Nothing.
sub insert {
	my $table = shift;

	$fieldlist = join ", ", @fields;
	$field_placeholders = join ", ", map {'?'} @fields;

	$insert_query = qq{
		INSERT INTO $table ( $fieldlist )
		VALUES ( $field_placeholders )
	};

	$sth = $dbh->prepare( $insert_query );
	# $insert_query = "INSERT INTO company ( name, code, ctime )
	#            VALUES ( ?, ?, ? )";

	for (@data_loh) {
		$sth->execute(@{$_}{@fields})
	}
}

#----- Main ------------------------------------------------------------------

#----- COMPANIES -------------------------------------------------------------
@fields = (qw(name code ctime));

@data_loh = (
	{ name => "Tomax Inc.",    code => "TMX",  ctime => lib::time::now() },
	{ name => "Duckwall/ALCO", code => "DW",   ctime => lib::time::now() },
	{ name => "Mud Bay",       code => "MB",   ctime => lib::time::now() }
);

insert( "company" );


#----- DEVICES ---------------------------------------------------------------
@fields = (qw(hostname rackpos serialno ctime));

@data_loh = (
	{ hostname => "testdevice1", rackpos => "Y16U01",  serialno => "EZ432398MMR4", ctime => lib::time::now() },
	{ hostname => "testdevice2", rackpos => "Y16U02",  serialno => "VW2123345565", ctime => lib::time::now() },
	{ hostname => "testdevice3", rackpos => "Y16U03",  serialno => "YT4848484848", ctime => lib::time::now() }
);

insert( "device" );


#----- PROPERTIES ------------------------------------------------------------
@fields = (qw(name value ctime));

@data_loh = (
	{ name => "Model", value => "v40z",      ctime => lib::time::now() },
	{ name => "Model", value => "v20",       ctime => lib::time::now() },
	{ name => "Model", value => "Dell Hell", ctime => lib::time::now() },

	{ name => "Vendor", value => "Cisco",            ctime => lib::time::now() },
	{ name => "Vendor", value => "NetApp",           ctime => lib::time::now() },
	{ name => "Vendor", value => "Sun Microsystems", ctime => lib::time::now() },
	{ name => "Vendor", value => "HP",               ctime => lib::time::now() },
	{ name => "Vendor", value => "Dell",             ctime => lib::time::now() }
);


insert( "property" );


#----- OWNER -----------------------------------------------------------------
@fields = (qw(device_id company_id ctime));

@data_loh = (
	{ device_id => 1, company_id => 1, ctime => lib::time::now() },
	{ device_id => 2, company_id => 2, ctime => lib::time::now() },
	{ device_id => 3, company_id => 2, ctime => lib::time::now() }
);


insert( "ownerlink" );



#----- USER -----------------------------------------------------------------
@fields = (qw(device_id company_id ctime));

@data_loh = (
	{ device_id => 1, company_id => 1, ctime => lib::time::now() },
	{ device_id => 1, company_id => 2, ctime => lib::time::now() },
	{ device_id => 1, company_id => 3, ctime => lib::time::now() },
	{ device_id => 2, company_id => 2, ctime => lib::time::now() },
	{ device_id => 3, company_id => 2, ctime => lib::time::now() }
);

insert( "userlink" );



#----- PROPLINK ---------------------------------------------------------------
@fields = (qw(device_id property_id ctime));

@data_loh = (
	{ device_id => 1, property_id => 1, ctime => lib::time::now() },
	{ device_id => 1, property_id => 6, ctime => lib::time::now() },
	{ device_id => 2, property_id => 2, ctime => lib::time::now() },
	{ device_id => 3, property_id => 3, ctime => lib::time::now() }
);

insert( "proplink" );




dao::saconnect::disconnect( $dbh );

exit (0);
