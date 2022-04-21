package lib::updateaccount;

use FindBin qw( $Bin );
use lib "$Bin/..";

use dao::account;
use lib::passwdutils;

use strict;



#----- addAccount ------------------------------------------------------------
# Add a new user to the system. Note: this function does not address setting 
# the password. See resetpwd().
# Parameters: 
#    dbh = handle to a db connection.
#    uid = the next UID in sequence.
#    gid = the primary group name (eg. sysadmin, dba, etc)
#    homedir = path to the home dir
#    gecos = the full name of the user
#    username = user's login name
sub addAccount {
	my $dbh = shift;
	my $uid = shift;
	my $gid = shift;
	my $homedir = shift;
	my $gecos = shift;
	my $username = shift;

	dao::account::addAccount( $dbh, $uid, $gid, $homedir, $gecos, $username );

}



#----- deleteAccount ------------------------------------------------------------
# Delete user's account and group references.
# Parameters:  (dbh, username)
sub deleteAccount {
	my $dbh = shift;
	my $username = shift;

	dao::account::deleteAccount( $dbh, $username );
}



#----- setPassword --------------------------------------------------------------
# Parameters: 
#	dbh = handle to a db connection.
#	username = username to affect
#	password = plain text password to be encrypted here.
# Note: this function assumes you have already validated the password. 
# See the "vaidatePassword()" funciton in the lib/passwdutils.pm module.
sub setPassword {
	my $dbh = shift;
	my $username = shift;
	my $password = shift;

	my $md5 = lib::passwdutils::genMD5( $password );

	# Set lastchange (-d) to today's date
	my $lastchange = lib::passwdutils::getLastchange();

	dao::account::setPassword( $dbh, $username, $md5, $lastchange );
}



#----- resetpwd --------------------------------------------------------------
# Parameters: 
#	dbh = handle to a db connection.
#	username = username to affect
sub resetpwd {
	my $dbh = shift;
	my $username = shift;

	my $md5password = lib::passwdutils::genMD5( $username );
	my $lastchange = lib::passwdutils::getLastchange10();
	
	dao::account::setPassword( $dbh, $username, $md5password, $lastchange );
}



#----- setFullName -------------------------------------------------------------
sub setFullName {
        my $dbh = shift;
        my $fullname = shift;
	my $username = shift;
        dao::account::updateFullName( $dbh, $fullname, $username );
}



#----- setHomeDirectory --------------------------------------------------------
sub setHomeDirectory {
        my $dbh = shift;
        my $homedir = shift;
        my $username = shift;
        dao::account::updateHomeDirectory( $dbh, $homedir, $username );
}



#----- setGID ------------------------------------------------------------------
sub setGID {
        my $dbh = shift;
        my $gid = shift;
        my $username = shift;
        dao::account::updateGID( $dbh, $gid, $username );
}



#----- setGroups ---------------------------------------------------------------
sub setGroups {
        my $dbh = shift;
        my $gname = shift;
        my $username = shift;
        dao::account::updateGroups( $dbh, $gname, $username );
}



#----- setUID ------------------------------------------------------------------
sub setUID {
        my $dbh = shift;
	my $uid = shift;
	my $username = shift;
	dao::account::updateUID( $dbh, $uid, $username );
}



#----- setUsername -------------------------------------------------------------
sub setUsername {
        my $dbh = shift;
        my $newusername = shift;
        my $username = shift;
        dao::account::updateUsername( $dbh, $newusername, $username );
}



#----- expire ------------------------------------------------------------------
# Set the expiration field in the shadow file to immediately expire the account.
sub expire {
        my $dbh = shift;
        my $username = shift;
        dao::account::expire( $dbh, $username );
}

#----- enable ------------------------------------------------------------------
# Clear the expiration field in the shadow file to immediately expire the account.
sub enable {
        my $dbh = shift;
        my $username = shift;
        dao::account::enable( $dbh, $username );
}

1;
