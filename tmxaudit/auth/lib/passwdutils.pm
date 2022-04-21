package lib::passwdutils;


use FindBin qw( $Bin );
use lib "$Bin/..";

use Data::Password qw(:all);
use Crypt::PasswdMD5 qw(unix_md5_crypt);
use dao::account;

use strict;



#----- genMD5 ----------------------------------------------------------------
# Parameters ( plaintext_password )
# Returns array (md5password)
sub genMD5 { 
	my $password = shift;

	my $salt = gensalt( 8 );
	return unix_md5_crypt( $password, $salt );
}
#----- gensalt ---------------------------------------------------------------
# Internal helper script for genMD5.
# Paramters ( count )
sub gensalt {
	my $count = shift;

	my @salt_chars = ('.', '/', 0 .. 9, 'A' .. 'Z', 'a' .. 'z' );
	my $salt;

	for (1..$count) {
		$salt .= (@salt_chars)[rand @salt_chars];
	}

	return $salt;
}



#----- genMD5WithSalt --------------------------------------------------------
# Parameters ( plaintext_password, salt)
# Returns array (md5password)
sub genMD5WithSalt { 
	my $password = shift;

	my $salt = shift;
	return unix_md5_crypt( $password, $salt );
}



#----- getLastchange ----------------------------------------------------------------
# Parameters ()
# Returns scalar value setting lastchange to today's date.
sub getLastchange { 
	my $now = `/bin/date +%s`;
	$_ = $now/86400;
	my ($today) = /(\d+)./;
	
	return $today;
}



#----- getLastchange10 ----------------------------------------------------------------
# Parameters ()
# Returns scalar value setting lastchange to nearly 10 years ago so that the 
# password will naturally expire in two days.
# To be used with "resetpwd".
sub getLastchange10 { 
	# The fifth column of the shadow must be set to 3650
	# Example shadow file :  username:passwdhash:____:0:3650:7:1::
	# 86400 is the number of seconds in a day
	# 3648 equals 9 years 11 months 28 days
	my $expire = getLastchange();
	return ($expire - 3648);	
}



#----- authenticate ----------------------------------------------------------
# Parameters ( username, password )
# Returns boolean 0 if authentication fails, boolean 1 on success.
# Note: Though we are keeping a DES hash, we are currently only checking the 
# MD5. If we find we need DES in future, we'll enable it here.
sub authenticate {
	my $dbh = shift;
	my $username = shift;
	my $password = shift;

	my $dbmd5 = dao::account::getMD5( $dbh, $username );
	# Get the salt
	my @salt = split( /\$/, $dbmd5 );

	my $md5 = unix_md5_crypt( $password, $salt[2] );

	my $result = 0;
	if ($md5 eq $dbmd5) {
		$result = 1;
	}
	return $result;
}



#----- validatePassword ------------------------------------------------------
# Parameters ( dbh, username, password )
# Returns "undef" if password is OK; returns error string otherwise.
sub validatePassword {
	my $dbh = shift;
	my $username = shift;
	my $password = shift;

	# Fail if password contains username.
	if ( $password =~ m/$username/i ) {
		return "Username must not be part of the password.";
	}

	# Fail if password contains first or lastname.
	my @row = dao::account::getUserInfo( $dbh, $username );
	my @fullname = split( / /, $row[3] );
	foreach my $fname (@fullname) {
		if ( $password =~ /$fname/i ) {
			return "Name must not be part of the password.";
		}
	}

	# Fail if password has been set within sh_min time period:	
	my $sh_lastchange = $row[7];
	my $sh_min        = $row[8];
	my $todayepoch    = getLastchange();
	if (($todayepoch - $sh_lastchange) < $sh_min) {
		return "Password cannot be reset within [$sh_min] days. (Contact SysAdmin for override.)";
	}

	# Fail if new password is same as previous password.
	if (authenticate( $dbh, $username, $password )) {
		return "Reuse of current password is not allowed.";
	}

	# Set exported vars from Data::Password module:
	$MINLEN = 8;     # (6) Minimum number of characters allowed.
	$MAXLEN = 20;    # (8) Maximum number of characters allowed.
	$DICTIONARY = 5; # (5) Minimal length for dictionary words that are not allowed to appear in the password.
	$FOLLOWING = 3;  # (3) Maximal length of characters in a row to allow if the same or following.
	$FOLLOWING_KEYBOARD = 1; # (1) Disallow following keys on keyboard (eg. qwerty)
	$GROUPS = 2;     # (2) Groups of characters are lowercase letters, uppercase letters, digits and the rest of the allowed characters. Set $GROUPS to the number of minimal character groups a password is required to have.
	return IsBadPassword( $password );
}


1;
