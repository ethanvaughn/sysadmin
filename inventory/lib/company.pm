package lib::company;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::company;


#----- getCompanyList ---------------------------------------------------------
# Get a list of all companies. 
# Arguments: None.
# Returns: Array ref of hash refs (AOH).
sub getCompanyList {
	my $dbh = shift;
	return dao::company::getCompanyList( $dbh );
}



#----- getCompanyById ---------------------------------------------------------
# Get details for a single company. 
# Arguments: ($dbh, $id)
# Returns: Hash ref.
sub getCompanyById {
	my $dbh = shift;
	my $id = shift;
	return dao::company::getCompany( $dbh, ["id", $id] );
}



#----- getCompanyByName -------------------------------------------------------
# Get details for a single company. 
# Arguments: ($dbh, $name)
# Returns: Hash ref.
sub getCompanyByName {
	my $dbh = shift;
	my $name = shift;
	return dao::company::getCompany( $dbh, ["name", $name] );
}



#----- getCompanyByCode -------------------------------------------------------
# Get details for a single company. 
# Arguments: ($dbh, $code)
# Returns: Hash ref.
sub getCompanyByCode {
	my $dbh = shift;
	my $code = shift;
	return dao::company::getCompany( $dbh, ["code", $code] );
}



#----- updateCompanyById ------------------------------------------------------
sub updateCompany {
	my $dbh = shift;
	my $rec = shift;
	return dao::company::updateCompany( $dbh, $rec );
}



#----- addCompany ------------------------------------------------------
sub addCompany {
	my $dbh = shift;
	my $rec = shift;
	return dao::company::addCompany( $dbh, $rec );
}



#----- delCompanyById ---------------------------------------------------
sub delCompanyById {
	my $dbh = shift;
	my $id = shift;
	return dao::company::delCompany( $dbh, ["id", $id] );
}



1;
