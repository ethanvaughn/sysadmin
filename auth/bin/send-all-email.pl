#!/usr/bin/perl

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use Net::SMTP;

use dao::saconnect;
use lib::getaccount;

use strict;



# ----- Globals --------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();



# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 'h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});
}



#----- usage_exit ------------------------------------------------------------
sub usage_exit {
	print <<EOL;

Send STDIN as an email to all central-auth users.

Usage:
cat file | $0

EOL
	exit (1);
}



#----- main ------------------------------------------------------------------

# Get STDIN: 
my $body;
my $subject;
while (<>) {
	if ($_ =~ /^Subject:/) {
		$subject = $_;
		next;
	}
	$body .= $_;
}
chomp( $subject );
$subject =~ s/^Subject: *(.*)/$1/;


# Get a list of usernames
my $dbh = dao::saconnect::connect();
($dbh) || die "FATAL: Unable to connect to database.";

my $acctref = lib::getaccount::getAccounts( $dbh );
my $errstr = $dbh->errstr;
($errstr) && die "FATAL: $errstr";

dao::saconnect::disconnect( $dbh );


# Make an array of recipients:
my @recipients;
foreach my $username (keys( %{$acctref} )) {
	push( @recipients, "$username\@tomax.com" );
}


# Set the email vars:
my $ServerName = "10.24.74.9";
my $MailFrom = "sysadmin\@tomax.com";


# Connect to the server
my $smtp = Net::SMTP->new( $ServerName )
		or die "Couldn't connect to server $ServerName: $!";
																											  
																											  
$smtp->mail( $MailFrom );
$smtp->recipient( @recipients );

# Start the mail
$smtp->data();

# Send the header.
$smtp->datasend( "Subject: $subject\n" );
$smtp->datasend( "\n" );

# Send the body
$smtp->datasend( $body );
$smtp->datasend( "\n" );

# Send the termination string
$smtp->dataend();
$smtp->quit();

print "\nEmail dispatched.\n\n";

exit 0;
