package dao::tmxconnect;

use DBI;

use strict;

#----- connect() -----------------------------------------------------------------
# Get a db connection and pass connection handle to caller.
# Returns db connection handle.
sub connect {
	my $dbname = "tmxaudit";
	my $user = "tmxaudit";
	my $pass = "ert5foo";

	return DBI->connect( "dbi:Pg:dbname=$dbname", $user, $pass ) or die DBI::errstr;
}


#----- disconnect() -----------------------------------------------------------------
# Close the database connection.
# Parameters: data base handle.
# Returns nothing.
sub disconnect {
	my $dbh = shift;
	$dbh->disconnect();
}


1;

