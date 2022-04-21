package dao::account;
#use Exporter;
#@ISA = ('Exporter');
#@EXPORT = qw(&getUsernameList);

use strict;

#----- getMD5 -------------------------------------------------------
# parameters: (dbh, username)
# returns scalar containing MD5 has for the user.
sub getMD5 {
	my $dbh = shift;
	my $username = shift;

	my $sqlstr = <<SQL;
		SELECT  md5_passwd
		FROM posixaccount 
		WHERE username='$username'
SQL

	my ($md5_passwd) = $dbh->selectrow_array( $sqlstr );
	return $md5_passwd;
}



#----- getNextUid -------------------------------------------------------
# parameters: (dbh)
# returns scalar containing next useable UID.
sub getNextUid {
	my $dbh = shift;

	my @row = $dbh->selectrow_array( "SELECT uid FROM posixaccount ORDER BY uid DESC" );
	return $row[0] + 1;
}



#----- getUsernameList -------------------------------------------------------
# parameters: (dbh)
# returns dataset of username fields.
sub getUsernameList {
	my $dbh = shift;

	my $sqlstr = <<SQL;
		SELECT  username, gecos
		FROM posixaccount 
		ORDER BY username
SQL

	return $dbh->selectall_hashref( $sqlstr, "username" );
}



#----- getUserInfo -------------------------------------------------------
# parameters: (dbh, username)
# returns array of account information for a specified user.
sub getUserInfo {
	my $dbh = shift;
	my $username = shift;

	my $sqlstr = <<SQL;
		SELECT  username, uid, gid, gecos, homedir, shell, 
		md5_passwd, sh_lastchange, sh_min, sh_max, sh_warn, 
		sh_inact, sh_expire
		FROM posixaccount 
		WHERE username='$username'
SQL

	return $dbh->selectrow_array( $sqlstr );
}



#----- getAccounts -------------------------------------------------------
# parameters: (dbh)
# returns dataset of all accounts.
sub getAccounts {
	my $dbh = shift;

	my $sqlstr = <<SQL;
	SELECT  
		username,
		md5_passwd,
		uid, 
		gid, 
		gecos, 
		homedir, 
		shell
	FROM posixaccount 
	ORDER BY username
SQL

	return $dbh->selectall_hashref( $sqlstr, "username" );
}



#----- getShadowAttr -----------------------------------------------------
# parameters: (dbh)
# returns dataset of shadow fields for all accounts.
sub getShadowAttr {
	my $dbh = shift;

	my $sqlstr = <<SQL;
	SELECT  
		username,
		md5_passwd,
		sh_lastchange, 
		sh_min, 
		sh_max, 
		sh_warn, 
		sh_inact,
		sh_expire
	FROM posixaccount 
	ORDER BY username
SQL

	return $dbh->selectall_hashref( $sqlstr, "username" );
}



#----- setPassword --------------------------------------------------------------
# parameters: (dbh, username, md5password, lastchange)
# modifies a users md5password, lastchange fields
sub setPassword {
	my $dbh = shift;
	my $username = shift;
	my $md5password = shift;
	my $lastchange = shift;


	# Settings for password rotation policy:
	my $MIN  = "14";  # Days before change allowed (-m); ie. min days between password changes.
	my $MAX  = "90"; # Days before change required (-M).
	my $WARN = "7";  # Days warning before change (-W).
	

	my $sqlstr = <<SQL;
	UPDATE posixaccount SET
		md5_passwd='$md5password',
		sh_lastchange='$lastchange',
		sh_min='$MIN',
		sh_max='$MAX',
		sh_warn='$WARN',
		mtime='now'
		WHERE username='$username'
SQL

	$dbh->do( $sqlstr );
}



#----- addAccount ------------------------------------------------------------
# Insert new account into the posixaccount table. Note: password is not set.
# Parameters: 
#    dbh = handle to a db connection.
#    uid = the next UID in sequence.
#    gid = the primary group name (eg. sysadmin, dba, etc)
#    homedir = path to the home dir
#    fname = the full name of the user
#    username = user's login name
sub addAccount {
	my $dbh = shift;
	my $uid = shift;
	my $gid = shift;
	my $homedir = shift;
	my $gecos = shift;
	my $username = shift;

	my $sqlstr = <<SQL;
	INSERT INTO posixaccount (
		uid, 
		gid, 
		homedir, 
		gecos,
		username
	)
	VALUES (?, ?, ?, ?, ?)
SQL

	my $sth = $dbh->prepare( $sqlstr );
	$sth->execute( $uid, $gid, $homedir, $gecos, $username );
}



#----- deleteAccount ------------------------------------------------------------
# Delete the account. Due to database foreign key relations, this simple 
# delete statement will remove the account and any records in the 
# accountgrouplink table that reference that account.
# Parameters: (dbh, username)
sub deleteAccount {
	my $dbh = shift;
	my $username = shift;


	my $sqlstr = "DELETE FROM posixaccount WHERE username=\'$username\'";
	$dbh->do( $sqlstr );
}

#----- updateFullName ----------------------------------------------------------
sub updateFullName {
        my $dbh = shift;
        my $fullname = shift;
	my $username = shift;
        my $sqlstr = "UPDATE posixaccount SET gecos = \'$fullname\' where username=\'$username\'";
        $dbh->do( $sqlstr );
}

#----- updateHomeDirectory -----------------------------------------------------
sub updateHomeDirectory {
        my $dbh = shift;
        my $homedirectory = shift;
        my $username = shift;
        my $sqlstr = "UPDATE posixaccount SET homedir = \'$homedirectory\' where username =\'$username\'";
        $dbh->do( $sqlstr );
}

#----- updateGID ---------------------------------------------------------------
sub updateGID {
        my $dbh = shift;
        my $gid = shift;
        my $username = shift;
        my $sqlstr = "UPDATE posixaccount SET gid = \'$gid\' where username =\'$username\'";
        $dbh->do( $sqlstr );
}

#----- updateGroups ------------------------------------------------------------
sub updateGroups {
        my $dbh = shift;
        my $gname = shift;
        my $username = shift;
        my $sqlstr = "DELETE from accountgrouplink where accountname  =\'$username\'";
        $dbh->do( $sqlstr );

	my @groups = split(',', $gname);
	foreach my $val (@groups) {
	my $sqlstr = "INSERT INTO accountgrouplink VALUES (\'$username\', \'$val\')";
	$dbh->do( $sqlstr );
	}
}
					
#----- updateUID ---------------------------------------------------------------
sub updateUID {
	my $dbh = shift;
	my $uid = shift;
	my $username = shift;
	my $sqlstr = "UPDATE posixaccount SET uid = \'$uid\' where username =\'$username\'";
	$dbh->do( $sqlstr );
}

#----- updateUsername ----------------------------------------------------------
sub updateUsername {
	my $dbh = shift;
	my $newusername = shift;
	my $username = shift;
	my $sqlstr = "UPDATE posixaccount SET username = \'$newusername\' where username =\'$username\'";
	$dbh->do( $sqlstr );
}

#----- expire ----------------------------------------------------------
sub expire {
	my $dbh = shift;
	my $username = shift;
	my $sql = "UPDATE posixaccount SET sh_expire = \'113\' where username =\'$username\'";
	$dbh->do( $sql );
}

#----- enable ----------------------------------------------------------
sub enable {
	my $dbh = shift;
	my $username = shift;
	my $sql = "UPDATE posixaccount SET sh_expire = \'\' where username =\'$username\'";
	$dbh->do( $sql );
}

1;
