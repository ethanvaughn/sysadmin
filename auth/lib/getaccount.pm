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


#----- mkPasswd -------------------------------------------------------
sub mkPasswd {
	my $dbh = shift;

	my @result;
	
	my $acctref = getAccounts( $dbh );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: $errstr";

	foreach my $key (keys( %{$acctref} )) {
		my $rec = "$acctref->{$key}->{'username'}:x:$acctref->{$key}->{'uid'}:$acctref->{$key}->{'gid'}:$acctref->{$key}->{'gecos'}:$acctref->{$key}->{'homedir'}:$acctref->{$key}->{'shell'}";
		push( @result, $rec );
	}
	
	return \@result;
}


#----- getShadowAttr -----------------------------------------------------
# Parameters: dbh = handle to a db connection.
# Returns dataset of all shadow information suitable for creating a 
# shadow text file with embedded MD5 hashes.
sub getShadowAttr {
	my $dbh = shift;

	return dao::account::getShadowAttr( $dbh );
}



#----- mkShadow -----------------------------------------------------
sub mkShadow {
	my $dbh = shift;

	my @result;
	
	my $acctref = getShadowAttr( $dbh );
	my $errstr = $dbh->errstr;
	($errstr) && die "FATAL: $errstr";

	foreach my $key (keys( %{$acctref} )) {
		# These fields are usually NULL in the db. This should silence the "uninitialized value" warnings:
		my $sh_inact  = "" if (! defined $acctref->{$key}->{'sh_inact'});
		my $sh_expire = "" if (! defined $acctref->{$key}->{'sh_expire'});
		my $rec = "$acctref->{$key}->{'username'}:$acctref->{$key}->{'md5_passwd'}:$acctref->{$key}->{'sh_lastchange'}:$acctref->{$key}->{'sh_min'}:$acctref->{$key}->{'sh_max'}:$acctref->{$key}->{'sh_warn'}:$sh_inact:$sh_expire:";
		push( @result, $rec );
	}

	return \@result;
}



1;
