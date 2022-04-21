package dao::saconnect;

use FindBin qw( $Bin );
use lib "$Bin/..";

use DBI;

use lib::conf;

use strict;



#----- connect() -----------------------------------------------------------------
# Get a db connection and pass connection handle to caller.
# Returns db connection handle.
sub connect {
        return DBI->connect( $DBSTR, $DBUSER, $DBPASS ) or die DBI::errstr;
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

