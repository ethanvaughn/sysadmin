#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";

use Net::SMTP;
use ac;
use strict;

# ----- Globals --------------------------------------------------------------

sub usage_exit {
	print <<EOL;

Send notification of errors.

Usage:
$0 "Subject line." "Error message." "sysadmin-oncall-pager\@localhost"

EOL
	exit (1);
}



# ----- Main -----------------------------------------------------------------
my $hostname = ac::normHostname( `hostname` );
# TODO: Change this. Find some other way (PERL module?) since this only works
# on Linux (not solaris) and then only if the IP we care about is eth0. 
# ('course, this is the 90% solution and there's still the problem of determining
# which of the many ifaces you want ...)
my $ipaddr = `ifconfig eth0 | grep 'inet addr' | cut -d":" -f2 | cut -d" " -f1`;
chomp $ipaddr;

# Grok command-line args
my $subject = shift;
my $msg = shift;
my $mailto = shift;

# Check requred params
if ($subject eq "" or $msg eq "" or $mailto eq "") {
	usage_exit();
}

# Set the email vars:
my $servername = "10.24.74.9";
my $mailfrom = "noreply\@tomax.com";
my $body = "
host [$hostname] at [$ipaddr]

$msg
";



# Connect to the server
#my $smtp = Net::SMTP->new( $servername, Debug=>1 )
my $smtp = Net::SMTP->new( $servername )
		or die "Couldn't connect to server $servername: $!";


$smtp->mail( $mailfrom );
$smtp->to( $mailto );


# Start the mail
$smtp->data();

# Send the header.
$smtp->datasend( "SendTo: $mailto\n" );
$smtp->datasend( "Subject: $subject\n" );
$smtp->datasend( "\n" );

# Send the body
$smtp->datasend( $body );
$smtp->datasend( "\n" );

# Send the termination string
$smtp->dataend();
$smtp->quit();

#print( "Email dispatched.\n\n" );


exit 0;
