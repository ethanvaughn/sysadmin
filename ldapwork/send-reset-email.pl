#!/usr/bin/perl

use Net::SMTP;
use strict;


my $usage = "
Notify user of LDAP password reset.

Usage:
send-reset-email.pl username

   username = The LDAP user whose passwd was reset.

";

# Grok command-line args
my $username = shift;

# Username is required. Show usage if it is missing.
if ($username eq "") {
	print $usage;
	exit( 1 );
}

# Set the email vars:
my $ServerName = "10.24.74.9";
#my $MailFrom = "Retail.net\@tomax.com";
my $MailFrom = "sysadmin\@tomax.com";
my $MailTo = "$username\@tomax.com";
my $body = "
Your LDAP password has been reset to your username: [$username].
** This password is temporary and will expire after 1 day. **

Please login to _any_LDAP_host_ using SSH (aka. PuTTY or SecureCRT
in Windows) and update your password using the \"passwd\" command.

For example, if your host is 10.24.74.9:

    \$> ssh $username\@10.24.74.9
    $username\@10.24.74.9's password:$username

    \$> passwd

    Changing password for user $username.
    Enter login(LDAP) password: $username
    New UNIX password: [secret]
    Retype new UNIX password: [secret]
    LDAP password information changed for $username
    passwd: all authentication tokens updated successfully.

";

# Connect to the server
#my $smtp = Net::SMTP->new( $ServerName, Debug=>1 )
my $smtp = Net::SMTP->new( $ServerName )
		or die "Couldn't connect to server $ServerName: $!";


$smtp->mail( $MailFrom );
$smtp->to( $MailTo );


# Start the mail
$smtp->data();

# Send the header.
$smtp->datasend( "SendTo: $MailTo\n" );
$smtp->datasend( "Subject: LDAP Password Reset \n" );
$smtp->datasend( "\n" );

# Send the body
$smtp->datasend( $body );
$smtp->datasend( "\n" );

# Send the termination string
$smtp->dataend();
$smtp->quit();

print( "Email dispatched.\n\n" );


exit 0;
