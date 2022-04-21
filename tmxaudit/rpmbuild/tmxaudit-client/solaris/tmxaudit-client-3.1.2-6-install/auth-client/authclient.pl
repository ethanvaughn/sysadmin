#!/usr/bin/perl

use FindBin qw( $Bin );
use lib "$Bin";

use Sys::Syslog;

use conf;
use ac;

use strict;


#----- Globals ---------------------------------------------------------------
my $msg = "";

my @localfiles = (
	"$WORKDIR/passwd.l",
	"$WORKDIR/shadow.l",
	"$WORKDIR/group.l"
);

my @remotefiles = (
	"$WORKDIR/passwd.r",
	"$WORKDIR/shadow.r",
	"$WORKDIR/group.r"
);

my $TTMP = "/tmp/tmxaudit";
`mkdir -p $TTMP`;
my @tmpfiles = (
	"$TTMP/passwd",
	"$TTMP/shadow",
	"$TTMP/group"
);

my @keyaccounts = (
	"root",
	"sshd",
	"tmxaudit"
);

my @keygroups = (
	"root",
	"dba",
	"sysadmin"
);



#----- Main ------------------------------------------------------------------
openlog( $0, 'cons', 'user' );

# Get hostname and normalize
my $hostname = ac::normHostname( `hostname` );

# Retrieve the auth bundle:
$msg = ac::getBundle( $HOST, $hostname );

# If the tar file doesn't exist, do nothing.
if ($msg =~ /No such file/) {
	syslog( 'info', '%s', "No changes from auth server." );
	closelog();
	exit (0);
}

# Check for other error conditions during retieval:
if ($msg ne "") {
	my $subject = "FATAL: retrieving: [$hostname.tar].";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


# Extract the bundle:
$msg = ac::extractBundle( $WORKDIR, "$hostname.tar" );
if ($msg ne "") {
	my $subject = "FATAL: extracting [$hostname.tar].";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


# Extract the local portions:
$msg = ac::getLocalPasswd( "/etc/passwd", $localfiles[0], "/etc/shadow", $localfiles[1] );
if ($msg ne "") {
	my $subject = "FATAL: creating local auth files:";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}

$msg = ac::getLocalGroup( "/etc/group", $localfiles[2] );
if ($msg ne "") {
	my $subject = "FATAL: creating local group file:";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


$msg = ac::mkComposit( $WORKDIR, $TTMP );
if ($msg ne "") {
	my $subject = "FATAL: creating composit auth files:";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


$msg = ac::chkEmpty( @localfiles, @remotefiles, @tmpfiles );
if ($msg ne "") {
	my $subject = "FATAL: composit auth files empty!:";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


$msg = ac::verifyAccounts( \@tmpfiles, \@keyaccounts, \@keygroups );
if ($msg ne "") {
	my $subject = "FATAL: key accounts missing!:";
	#Send notification to sysadmin oncall:
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-pager\@localhost"`;
	`$Bin/notify-oncall.pl "$subject" "$msg" "sysadmin-oncall-email\@localhost"`;
	syslog( 'info', '%s', $subject );
	syslog( 'info', '%s', "       $msg." );
	closelog();
	exit (1);
}


# Passed the checks, rotate backup and go live:
`$Bin/backup.sh`;
`mv $tmpfiles[0] /etc/passwd`;
`mv $tmpfiles[1] /etc/shadow`;
`mv $tmpfiles[2] /etc/group`;

# Set the permissions so the tmxaudit user has group write access:
`chown root:root /etc/passwd /etc/shadow /etc/group`;
`chmod 664 /etc/passwd /etc/group`;
`chmod 660 /etc/shadow`;

# Clean up
`rm -rf $TTMP`;
`mkdir -p $WORKDIR-last`;
`mv -f $WORKDIR/* $WORKDIR-last/`;

closelog();
exit (0);
