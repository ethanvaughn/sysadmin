package lib::updategroup;

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::group;

use strict;

#----- addGroup --------------------------------------------------------
# Parameters: ( dbh, gid, groupname )
sub addGroup {
	my $dbh = shift;
	my $gid = shift;
	my $groupname = shift;

	dao::group::addGroup( $dbh, $gid, $groupname );
}


#----- addUserToGroup --------------------------------------------------------
# Parameters: ( dbh, username, groupname )
sub addUserToGroup {
	my $dbh = shift;
	my $username = shift;
	my $groupname = shift;

	dao::group::addUserToGroup( $dbh, $username, $groupname );
}



#----- setGroupName --------------------------------------------------------
# Parameters: ( dbh, groupname, newname )
sub setGroupName {
	my $dbh = shift;
	my $groupname = shift;
	my $newname = shift;

	dao::group::setGroupName( $dbh, $groupname, $newname );
}



#----- deleteGroup ------------------------------------------------------------
# Delete group.
# Parameters:  (dbh, groupname)
sub deleteGroup {
	my $dbh = shift;
	my $groupname = shift;

	dao::group::deleteGroup( $dbh, $groupname );
}
1;
