#!/usr/bin/perl

#################################################################################################
#
# Name:		mail_send.pl
# Purpose:	Sends mail read off of STDIN with a given subject line and return address
#		basically, combines /bin/mail (command-line subject lines) and
#		/usr/sbin/sendmail (allows overriding of the envelope sender)
#		into one command.  It's a shame that there's no easier way to combine
#		the functionality of both commands
#
# $Id: mail_send.pl,v 1.5 2008/01/07 15:18:29 jkruse Exp $
# $Date: 2008/01/07 15:18:29 $
#
#################################################################################################

use strict;
use Net::SMTP;
use IO::Select;
use Getopt::Std;

my %args;							# The command-line arguments (subject and recipient)
my $sender = 'noreply@tomax.com';				# Who to spoof the sender as
my $timeout = 3;						# Timeout for reading STDIN
my $logger = '/usr/bin/logger';					# Location of syslog utility to log errors to syslog
my @body;							# The message body

getArgs();
readMessageBody();
sendMessage();

sub sendMessage {
	my $smtp = Net::SMTP->new('localhost',Timeout => 10);
	if ($smtp) {
		$smtp->mail($sender);
		$smtp->to($args{r});
		$smtp->data();
		$smtp->datasend('To: '.$args{r}."\n");
		$smtp->datasend('From: '.$sender."\n");
		$smtp->datasend('Subject: '.$args{s}."\n\n");
		$smtp->datasend(@body);
		$smtp->dataend();
		$smtp->quit();
	} else {
		logger($!);
		exit -1;
	}
}

sub readMessageBody {
	# This could be done with alarm, but select/poll (via the IO::Select module)
	# is both faster and lighter weight.  Not to mention the issue of concurrent
	# alarm signals, which are problematic
	my $s = IO::Select->new();
	$s->add(\*STDIN);
	my $cnt = $s->can_read($timeout);
	if ($cnt > 0) {
		@body = <STDIN>;
	} else {
		logger('No data received after '.$timeout.' seconds, aborting');
		exit -1;
	}
}

sub logger {
	# Logs messages to both STDOUT and syslog
	my $message = shift;
	if (!$message) {
		$message = 'No status message received, most likely a bug';
	}
	my $cmd = sprintf('%s %s:"%s"',$logger,$0,$message);
	print $0,' ERROR:',$message,"\n";
	system($cmd);
}

sub getArgs {
	my $count = 0;
	getopts('s:r:',\%args);
	if (exists($args{s})) {
		$count++;
	}
	if (exists($args{r})) {
		$count++;
	}
	if ($count != 2) {
		usage();
	}
	
}

sub usage {
	# In case the user is a moron
	print 'Usage: ',$0, ' -s <subject> -r <recipient>',"\n";
	exit -1;
}
