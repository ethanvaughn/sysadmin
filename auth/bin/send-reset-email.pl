#!/usr/bin/perl

use Net::SMTP;
use strict;

# ----- Globals --------------------------------------------------------------

sub usage_exit {
	print <<EOL;

Notify user of CVS password reset.

Usage:
send-reset-email.pl username

   username = The system user whose passwd was reset. Note: this username 
              must be a valid email address in the tomax.com domain.

EOL
	exit (1);
}



# ----- Main -----------------------------------------------------------------

# Grok command-line args
my $username = shift;

# Username is required. Show usage if it is missing.
if ($username eq "") {
	usage_exit();
}

# Set the email vars:
my $ServerName = "10.24.74.9";
my $MailFrom = "sysadmin\@tomax.com";
my $MailTo = "$username\@tomax.com";
my $subject = "Datacenter Password Reset for User [$username] ";
my $body = "
The password for your datacenter account has been reset to your login
user name [$username].

** THIS PASSWORD IS TEMPORARY and will expire after 1 day. **

Please browse to the following URL and update your password:

    http://10.24.74.13/authapp/changepass

IMPORTANT: The authentication files on the datacenter servers 
are automatically updated only once daily at 21:00. If you need 
access to a machine immediately, please send email to 'sysadmin' 
with the subject 'Auth Update Request'. 

Usage Note:

Using your datacenter account, you can \"switch user\" to a system
account using the \"sudo\" command prefix followed by the standard 
\"su\" command. For example, to change to the \"oracle\" user:

    \$> sudo su - oracle


Thank you,

Tomax Outsourcing Team
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
$smtp->datasend( "Subject: $subject\n" );
$smtp->datasend( "\n" );

# Send the body
$smtp->datasend( $body );
$smtp->datasend( "\n" );
																												  
# Send the termination string
$smtp->dataend();
$smtp->quit();

print( "Email dispatched.\n\n" );


exit 0;
