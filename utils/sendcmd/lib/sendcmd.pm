package lib::sendcmd;
use strict;

use FindBin qw( $Bin );
use lib "$Bin/..";

use Term::ReadKey;



#----- pwdprompt -------------------------------------------------------------
# Prompt user for a password by first turning off tty echo so the password
# is not printed on the screen.
# Returns the user's input.
sub pwdprompt {
	my $password;
	print "Datacenter password: ";
	ReadMode 2;
	chomp( $password = <STDIN>);
	ReadMode 1;
	print "\n";
	return $password;
}


1;
