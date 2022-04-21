#!/usr/bin/perl

use Sys::Syslog;

use strict;


# ----- Global ---------------------------------------------------------------
# Set up a global hash to contain the command-line arguments.
my %opt = ();
# Command line vars:
my $PROP='/etc/TMXHOST.properties';


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



#----- usage_exit() ----------------------------------------------------------
# Usage message goes to STDERR.
sub usage_exit() {
    print STDERR << "EOF";

Kill all running Xvnc sessions.

usage: 
    $0

EOF

    exit( 1 );
}



#----- checkProp() ----------------------------------------------------------
# Check for the properties file and the KILLVNC variable.
# Returns bool "true" only if the variable is read and is set to "yes".
sub checkProp() {
	my $killvnc = 'no';
	my $result = 0;

	# Open the property file.
	my $open = open( PROP, "<$PROP");
	if (!$open) {
		return $result;
	}
	
	# Locate the KILLVNC variable.
	while (<PROP>) {
		my $line = $_;
		if ($line =~ /^KILLVNC/) {
			chomp $line;
			my @tmp = split( /=/, $line );
			$killvnc = $tmp[1];
			last;
		}
	}
	close( PROP );
	
	if ($killvnc eq 'yes' || $killvnc eq 'Yes' || $killvnc eq 'YES') {
		$result = 1;
	} else {
		$result = 0;
	}

	return $result;
}




#----- Main ------------------------------------------------------------------
openlog( $0, 'cons', 'user' );

init();

if (!checkProp()) {
	syslog( 'info', '%s', "Property KILLVNC not set to 'yes' in file [$PROP]. Not killing Xvnc." );
	closelog();
	exit(0);
}

# The KILLVNC property = 'yes'. Proceed to kill Xvnc.
my @cmdout = `/bin/ps -A -o user,pid,args | /bin/grep -i [X]vnc | /usr/bin/tr -s ' ' | /bin/cut -d ' ' -f 1,2,3,4`;

if ($#cmdout < 0) {
	syslog( 'info', '%s', "No Xvnc sessions to kill." );
	closelog();
	exit(0);
}

foreach my $line (@cmdout) {
	chomp $line;
	my @fields = split( / /, $line );
	if (`grep -q $fields[0] /etc/passwd`) { 
		syslog( 'info', '%s', "Killing Xvnc sessions for user $fields[0]." );
		`su $fields[0] -c "PATH=\$PATH:/usr/X11R6/bin vncserver -kill $fields[3]" 2>&1 | logger -t killvnc -p syslog.info`;
	} else {
		syslog( 'info', '%s', "User $fields[0] no longer exists in /etc/passwd. Killing Xvnc sessions." );
		`kill -9 $fields[1]`;
	}
}


closelog();
exit (0);
