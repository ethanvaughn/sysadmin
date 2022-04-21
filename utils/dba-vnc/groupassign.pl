#!/usr/bin/perl

use strict;

# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $groupname = "";
my $username = "";


# ----- init() ---------------------------------------------------------------
# Process the command-line arguments.
sub init() {
    use Getopt::Std;

    # Validate args and load the opt hash:
    my $opt_string = 'g:hu:';
    getopts( "$opt_string", \%opt ) or usage_exit();

    # Show the usage if -h is in arg list:
    usage_exit() if ($opt{h});

    # Exit if any of the required args are missing:
    if (!$opt{g} or !$opt{u}) {
        print "\n";
        print "*** Please provide the required arguments. ***\n";
        print "\n";
        usage_exit();
    }

    # Passed all argument checks. Load the variables:
    $groupname = $opt{g} if $opt{g};
    $username = $opt{u} if $opt{u};
}



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
    print STDERR << "EOF";

Assign a user to the specified group.

usage: 
    $0 -g group -u username

    $0 -h  --> Show this usage.


examples: 
    $0 -g sysadmin -u evaughn 
    $0 -u jrandom -g testusers

EOF

    exit( 1 );
}


#----- print_error -----------------------------------------------------------
sub print_error {
    my $path = shift;
    my $msg = shift;

    print STDERR "\n";
    print STDERR "Unable to open file: $path\n";
    print STDERR "$msg\n";
    print STDERR "\n";

    usage_exit();
}




#----- Main ------------------------------------------------------------------

init();

my $epoch = `date "+%s"`;
chomp $epoch;
my $tmpfile = "/tmp/$epoch";

my $group = "/etc/group";
open( GROUP, "<$group")   or print_error( $group, $! );
open( TMP,   ">$tmpfile") or print_error( $tmpfile, $! );

my $i = 0;
while (<GROUP>) {
	my $line = $_;

	if ($line =~ /^$groupname:/) {
		chomp $line;

		# if user exists, do nothing and exit
		if ($line =~ /$username/) {
			exit 0;
		}

		# Get user list.
		# First split on the colon, then split on comma of userlist field:
		my @rec = split( /:/, $line );
		my @userlist = split( /,/, $rec[3] );

		if ($#userlist < 0) {
			# No users yet assigned. Simply add $username:
			$line = $line . "$username\n";
		} else {
			# Users are assigned. Append $username into comma list: 
			$line = $line . ",$username\n";
		}
	}

	print TMP $line;
} 

close( GROUP );
close( TMP );


# Backup group file:
`cp -f $group $group.bak`;

# Copy tmpfile over top:
`cp -f $tmpfile $group`;

# Clean tmpfile:
`rm -f $tmpfile`;

exit 0;
