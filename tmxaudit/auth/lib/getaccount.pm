package lib::getaccount;
#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = qw(&getusernamelist);

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::account;

use strict;



#----- getNextUid ------------------------------------------------------------
# returns scalar containing next uid.
sub getNextUid {
	my $dbh = shift;
	return dao::account::getNextUid( $dbh );
}



#----- getUsernameList -------------------------------------------------------
# Parameters: dbh = handle to a db connection.
# Returns dataset of all username fields.
sub getUsernameList {
	my $dbh = shift;
	return dao::account::getUsernameList( $dbh );
}


#----- genShadowedpasswd ----------------------------------------------------
sub genShadowedpasswd {
	my $dbh = shift;
	dao::account::genShadowedpasswd( $dbh );
}


#----- getAccounts -------------------------------------------------------
# Parameters: dbh = handle to a db connection.
# Returns dataset of all account information suitable for creating a 
# passwd text file with embedded MD5 hashes.
sub getAccounts {
	my $dbh = shift;

	return dao::account::getAccounts( $dbh );
}


#----- getShadowAttr -----------------------------------------------------
# Parameters: dbh = handle to a db connection.
# Returns dataset of all shadow information suitable for creating a 
# shadow text file with embedded MD5 hashes.
sub getShadowAttr {
	my $dbh = shift;

	return dao::account::getShadowAttr( $dbh );
}

1;
