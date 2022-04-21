package lib::mal;


use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::mal;


#----- getList ---------------------------------------------------------
# Get a list of all records. 
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getList {
	my $dbh = shift;
	return dao::mal::getList( $dbh );
}



#----- getClosedList ---------------------------------------------------------
# Get a list of closed records for the history view. 
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getClosedList {
	my $dbh = shift;
	return dao::mal::getClosedList( $dbh );
}



#----- getOpenList ---------------------------------------------------------
# Get a list of open records. 
# Arguments: ($dbh).
# Returns: Array ref of hash refs (AOH).
sub getOpenList {
	my $dbh = shift;
	return dao::mal::getOpenList( $dbh );
}



#----- getOpenListByService ---------------------------------------------------------
# Get a list of open records for a specific service and host. 
# Arguments: ($dbh, $hostname, $servicename).
# Returns: Array ref of hash refs (AOH).
sub getOpenListByService {
	my $dbh = shift;
	my $hostname = shift;
	my $servicename = shift;
	return dao::mal::getOpenListByService( $dbh, $hostname, $servicename );
}



#----- genRec ---------------------------------------------------------
# Generate a test record.
# Arguments: ($dbh).
# Returns: nothing.
sub genRec {
	my $dbh = shift;
	
	my $rec;
	$rec->{hostname} = "tmxtimbuktu";
	$rec->{ip} = "172.33.1.154";
	$rec->{servicename} = "AlertLog_ALCO_PROD";
	$rec->{level} = "CRIT";
	$rec->{msg} = "This is a multi-line test message.\nHere at ThinkGeek we are pretty lazy when it comes to technology. We expect our gadgets to do all the busywork while we focus on the high level important tasks like reading blogs.\nAnd now for line 3.";
	
	return dao::mal::insertRec( $dbh, $rec );
}



#----- insertRec ---------------------------------------------------------
# Arguments: ($dbh, $rec).
# Returns: nothing.
sub insertRec {
	my $dbh = shift;
	my $rec = shift;
	
	return dao::mal::insertRec( $dbh, $rec );
}



#----- closeRec ---------------------------------------------------------
# Get a list of all records. 
# Arguments: ($dbh, $rec_id).
# Returns: Array ref of hash refs (AOH).
sub closeRec {
	my $dbh = shift;
	my $rec_id = shift;
	return dao::mal::closeRec( $dbh, $rec_id );
}



#----- delRec ---------------------------------------------------------
# Arguments: ($dbh, $rec_id).
# Returns: none.
sub delRec {
	my $dbh = shift;
	my $rec_id = shift;
	return dao::mal::delRec( $dbh, ["id", $rec_id]);
}



1;
