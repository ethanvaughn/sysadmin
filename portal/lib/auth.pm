package lib::auth;

use FindBin qw( $Bin );
use lib "$Bin/..";




#----- getCookieValues ------------------------------------------------------
sub getCookieValues {
	my $q = shift;
	
	my $username = $q->cookie("tomaxportalusername");
	my $password = $q->cookie("tomaxportalpassword");
	my $customer = $q->cookie("tomaxportalcustomer");
	
	return ($username, $password, $customer);
}




#----- isValidUser -----------------------------------------------------------
# Authenticate the credentials. 
sub isValidUser {
	my $user = shift;
	my $pass = shift;

	my $passwd_file = '/u01/app/portal/etc/users';

	open( FILE, $passwd_file ) || die 'Unable to read auth file';
	my $retval = undef;
	while(<FILE>) {
		next if /^#/;
		chomp;
		my ($cust_code,$file_user,$file_pass) = split(/,/,$_);
		if ($user eq $file_user && $pass eq $file_pass) {
			$retval = $cust_code;
			last;
		}
	}
	close( FILE );
	
	return $retval;
}


1;
