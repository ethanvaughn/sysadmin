#!/usr/bin/perl
use strict;

# Set the include path.
use FindBin qw( $Bin );
use lib "$Bin/..";

use lib::sendcmd;


#----- Global ----------------------------------------------------------------
# Path the the rssh.pl program:
my $RSSH = '/u01/app/utils/sendcmd/bin/rssh.pl';

my %opt;
my $command;
my $password;
my $listfile;
my $logpath;
my $username;


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init {
	use Getopt::Std;

	# Validate args and load the opt hash:
	my $opt_string = 'c:f:hl:p:u:';
	getopts( "$opt_string", \%opt ) or usage_exit();

	# Show the usage if -h is in arg list:
	usage_exit() if ($opt{h});

    # Exit if required args are missing:
    if (!$opt{f}) {
    print "\n";
        print "*** Please provide the required arguments. ***\n";
        print "\n";
        usage_exit();
    }

	# Passed all argument checks. Load the variables:
	$command  = $opt{c} if $opt{c};
	$password = $opt{p} if $opt{p};
	$listfile = $opt{f} if $opt{f};
	$logpath  = $opt{l} if $opt{l};
	$username = $opt{u} if $opt{u};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit {
	print STDERR << "EOF";

Wrapper for the rssh.pl script. This script will prompt for optional fields if no
value is specified on the command-line, then execute a command on each server in 
the listfile. The output will be stored in one log-file per server in the path: 

    logpath/<IP>.log

The logpath parameter defaults to ./ if not provided.

Usage: 
    $0 [-u username] [-p password] [-l logpath] [-c "command"] -f listfile

    $0 -h  --> Show this usage.

EOF
	exit( 1 );
}


#----- Main ------------------------------------------------------------------
init();
# Sanity check on the listfile:
if ( ! -f $listfile ) {
	print "\n";
	print "*** ERROR *** File not found: $listfile\n";
	print "\n";
	usage_exit();
}

if ($username eq '') {
	print 'Datacenter username: ';
	chomp( $username = <> );
}

if ($password eq '') {
	$password = lib::sendcmd::pwdprompt();
}

if ($logpath eq '') {
	$logpath = "./";
}

if ($command eq '') {
	print 'Command to send: ';
	chomp( $command = <> );
}

open( LIST, "<$listfile" ) ||
	die "Unable to open [$listfile] for read: $!\n";

# Clear any files already in the logpath
`rm  -f $logpath/*`;
	
my @child_pids;
while (<LIST>) {
	chomp;
	if (my $pid = fork()) {
		push( @child_pids, $pid );
	} elsif ($pid == 0) {
		sleep( 1 );
		exec( "$RSSH -u $username -p $password -l $logpath -s $_ -c \"$command\"" );
		exit (0);
	} else {
		die "** ERROR ** Unable to fork for $_.\n";
	}
}
close( LIST ); 

print "Spawned " . ($#child_pids + 1) . " children. Now waiting for the orphans.\n";
foreach (@child_pids) {
	waitpid( $_, 0 );
}

# Show the output
print "\n OUTPUT [bin/catlog.sh $logpath]\n";
my $output = `bin/catlog.sh $logpath`;
print $output;

exit (0);
