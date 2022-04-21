#!/usr/bin/perl
#
#  nagios-notify.pl
#
#  Used to schedule downtime for this host or for a specified service.
#
#  Request is passed to maintenance mail address on Nagios server.
#

use FindBin qw( $Bin );
use lib "$Bin";

use strict;

use Net::SMTP;
use Getopt::Long;
use Sys::Hostname;
use utils;


#----- Globals ----------------------------------------------------------------
my $prop = utils::get_host_properties();
my $switch;
my $cmd;

#----- Args -------------------------------------
my $action;
my $service;
my $notify;




#----- usage_exit() ----------------------------------------------------------
sub usage_exit {
	print STDERR <<EOL;

Start/Stop Nagios monitoring for the localhost and all services, or for the
specified service only.

Usage: $0 -A <on|off> [-S "service"] [-N "notify\@metoo.com"]

Examples:

$0 -A off -N "jrandom\@tomax.com"
$0 -A off -S "Disk Usage" -N "notify\@metoo.com"
$0 -A on -N "notify\@metoo.com"


EOL
	exit (1);
}




#----- main -------------------------------------------------------------------
# Gather the command-line args
GetOptions( 
	'S=s' => \$service,
	'A=s' => \$action,
	'N=s' => \$notify
);

# Lower-case these variables to deal with inconsistent user input
$action = lc( $action );

# The user can enter "on", "off" for the 'action' command-line arg:
if ($action eq 'off') {
	$switch="add";
} elsif ($action eq 'on') {
	$switch="del";
} else {
	print "\n".'Error: Action must be "on" or "off"'."\n";
	usage_exit();
}


if ( !$service ) {
	$cmd = $switch . '_h_' . $prop->{NAGIOS_HOSTNAME};
	print "\nSending request to turn $action all Service notifications for host $prop->{NAGIOS_HOSTNAME}\n";
} else {
	$cmd = $switch . '_hs_' . $prop->{NAGIOS_HOSTNAME} . '_' . $service;
	print "\nSending request to turn $action Service notifications for \"$service\"\n";
}


# Format and send it.
#my $smtp = Net::SMTP->new( $prop->{NAGIOS_SERVER}, Debug=>1 )
my $smtp = Net::SMTP->new( $prop->{NAGIOS_SERVER} )
		or die "Couldn't connect to server $prop->{NAGIOS_SERVER}: $!";

$smtp->mail( "notify\@$prop->{NAGIOS_HOSTNAME}" );
$smtp->to( 'maintenance@localhost' );

$smtp->data();
$smtp->datasend("From: notify\@$prop->{NAGIOS_HOSTNAME}\n");
$smtp->datasend("NOTIFY:$notify\n");
$smtp->datasend("MAINT:$cmd");

$smtp->dataend();
$smtp->quit();
