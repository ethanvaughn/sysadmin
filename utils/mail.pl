#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";

use strict;
use Net::SMTP;
use utils;




# ----- Globals --------------------------------------------------------------
my $prop = utils::get_host_properties();
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $subject = "";
my @addr_list;




# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
	use Getopt::Std;
	
	# Validate args and load the opt hash:
	my $opt_string = 's:h';
	getopts( "$opt_string", \%opt ) or usage_exit();
	
	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

	# Exit if any of the required args are missing:
	if (!$opt{s}) {
	print "\n";
		print "*** Please provide the required arguments. ***\n";
		print "\n";
		usage_exit();
	}

	# Exit if ARGV now has more than 1 arg:
	# (this should be the address list)
	usage_exit() if ($#ARGV ne 0);

	# Passed all argument checks. Load the variables:
	$subject = $opt{s} if $opt{s};
	@addr_list = split( /,/, $ARGV[0] );	
}




#----- usage_exit() ----------------------------------------------------------
sub usage_exit {
	print STDERR <<EOL;

Send email message received from STDIN to specified addresses.

Usage:
cat file  | mail.pl -s "This is the Subject" "addr1\@example.com,addr2\@tomax.com,...,addrN"

EOL
	exit (1);
}




# ----- Main -----------------------------------------------------------------
init();


# Set the email vars:
my $server_name = $prop->{NAGIOS_SERVER};
my $mail_from = "sysadmin\@tomax.com";
my @body = <STDIN>;


# Connect to the server
#my $smtp = Net::SMTP->new( $server_name, Debug=>1 )
my $smtp = Net::SMTP->new( $server_name)
		or die "Couldn't connect to server $server_name: $!";

$smtp->mail( $mail_from );
$smtp->recipient( @addr_list, { SkipBad => 1 } );


# Start the mail
$smtp->data();

# Send the header.
$smtp->datasend( "Subject: $subject\n" );
$smtp->datasend( "\n" );

# Send the body
$smtp->datasend( @body );
$smtp->datasend( "\n" );

# Send the termination string
$smtp->dataend();
$smtp->quit();

print( "Email dispatched.\n" );

exit 0;
