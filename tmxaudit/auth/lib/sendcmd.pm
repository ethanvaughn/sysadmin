package lib::sendcmd;

use FindBin qw( $Bin );
use lib "$Bin/..";

use Term::ReadKey;
use Expect;

use strict;


#----- Globals ---------------------------------------------------------------
#my $timeout = 30;
my $timeout = 5;


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



#----- sendcmd ---------------------------------------------------------------
# Parameters: ( username, password, command, listfile )
#
# Remote execution of command via SSH using username and password for each  
# server IP in the listfile..
#
# Returns nothing.
sub sendcmd {
	# Parameters
	my $username = shift;
	my $password = shift;
	my $command  = shift;
	my $listfile = shift;

	# Locals
	my @hosts = ();
	my $exp = new Expect;
	$exp->raw_pty( 1 );  

	# Get the list of datacenter servers:
	open( SERVERLIST, "<$listfile" ) ||
		die "Unable to open $listfile: $!\n\n";
	@hosts = <SERVERLIST>;
	close( SERVERLIST );

	foreach my $host (@hosts) {
		chomp $host;

		my $spawn_ok = 0;

		$exp = Expect->spawn( "ssh $username\@$host \"$command\"" )
			or die "Cannot spawn process: $!\n";

		$exp->log_stdout( 0 );

		$exp->expect( $timeout,
				'(yes/no)?',
				sub {
					$spawn_ok = 1;
					$exp->send( "yes\n" );
					exp_continue;
				},
				'password: ',
				sub {
					$spawn_ok = 1;
					$exp->send( "$password\n" );
					exp_continue;
				},
				'try again',
				sub {
					print "\nIncorrect password. Please try again.\n\n";
				},
				'',
				sub {
					$spawn_ok = 1;
				},
			[
				eof =>
				sub {
					if ($spawn_ok) {
						die "ERROR: premature EOF.\n";
					} else {
						die "ERROR: could not spawn.\n";
					}
				}
			],
			[
				timeout =>
				sub {
				  print "Process timed out.\n";
				}
			]
		);
		$exp->soft_close();

		print "\n[$host]\n";
		print $exp->before();
		print "\n";

	}

}



#----- changeInternalRoot ---------------------------------------------------------------
# Parameters: ( username, password, command, listfile )
#
# Remote execution of command via SSH using username and password for each  
# server IP in the listfile..
#
# Returns nothing.
sub changeInternalRoot {
	# Parameters
	my $username = shift;
	my $password = shift;
	my $command  = shift;
	my $listfile = shift;

	# Locals
	my @hosts = ();
	my $exp = new Expect;
	$exp->raw_pty( 1 );  

	# Get the list of datacenter servers:
	open( SERVERLIST, "<$listfile" ) ||
		die "Unable to open $listfile: $!\n\n";
	@hosts = <SERVERLIST>;
	close( SERVERLIST );

	foreach my $host (@hosts) {
		chomp $host;

		my $spawn_ok = 0;

		$exp = Expect->spawn( "ssh $username\@$host \"$command\"" )
			or die "Cannot spawn process: $!\n";

		$exp->log_stdout( 0 );

		$exp->expect( $timeout,
				'(yes/no)?',
				sub {
					$spawn_ok = 1;
					$exp->send( "yes\n" );
					exp_continue;
				},
				'password: ',
				sub {
					$spawn_ok = 1;
					$exp->send( "$password\n" );
					exp_continue;
				},
				'try again',
				sub {
					die "\nIncorrect password. Please try again.\n\n";
				},
				'',
				sub {
					$spawn_ok = 1;
				},
			[
				eof =>
				sub {
					if ($spawn_ok) {
						die "ERROR: premature EOF.\n";
					} else {
						die "ERROR: could not spawn.\n";
					}
				}
			],
			[
				timeout =>
				sub {
				  print "Process timed out.\n";
				}
			]
		);
		$exp->soft_close();

		print "\n[$host]\n";
		print $exp->before();
		print "\n";

	}

}

1;
