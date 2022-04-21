#!/usr/bin/perl

# Set the  path.
use FindBin qw( $Bin );

use Socket;
use Sys::Hostname;

use strict;


# ----- Globals -------------------------------------------------------------
my $hashRec = {};
my $listProbs = [];



# ----- submitCheck ----------------------------------------------------------
sub submitCheck {
	my ( $host, $port, $cmds ) = @_;

	# Validate commands
	if (!$host || !$port || !$cmds) {
		die 'submitCheck: FATAL: Missing host, port number, or commands reference\n';
	}

	# values: POST'd key/val pairs from $cmds (either as scalar or array)
	# header: the HTTP 1.0 header
	# length: the content length
	# build values first to determine the content-length (counter intuitive)
	my ($values, $header, $length); 
	# Build value string
	if (ref($cmds) eq 'SCALAR') {
		$$cmds =~ s/;/\$/g; # Semicolons need to be replaced as something else (try it, you'll see!)
		$length = length($$cmds)+4;
		$values.= "cmd=$$cmds";
	} elsif (ref($cmds) eq 'ARRAY') {
		for (my $i = 0; $i < scalar(@$cmds); $i++) {
			if ($i + 1 == scalar(@$cmds)) {
				$$cmds[$i] =~ s/;/\$/g;
				$values.= "cmd=@$cmds[$i]";
				$length+= (4 + length(@$cmds[$i]));
			} else {
				$$cmds[$i] =~ s/;/\$/g;
				$values.= "cmd=@$cmds[$i]&";
				$length+= (5 + length(@$cmds[$i]));
			}
		}
	} else {
		die 'submitCheck: FATAL: command string must be a scalar or array ref!';
	}

	# Build header
	$header .= "POST /pcgi/submitcheck.cgi HTTP/1.0\r\n";
	$header .= "Host: $host\r\n";
	$header .= "Content-Type: application/x-www-form-urlencoded\r\n";
	$header .= "Content-Length: $length\r\n";
	$header .= "\r\n";

	# Append values to header
	$header .= $values;

	# Connect socket
	my $proto = getprotobyname( 'tcp' );
	socket( FH, PF_INET, SOCK_STREAM, $proto) || die "submitCheck: FATAL: Unable to create socket: $!\n";
	my $sin = sockaddr_in( $port, inet_aton( $host ) );
	my $timeout = 10;

	eval {
		local $SIG{ALRM} = sub { die 'timeout' };
		alarm( $timeout );
		connect( FH, $sin ) || die "Connect error: $!";
		send( FH, $header, 0);
		alarm( 0 );
	};

	if ($@ =~ /^timeout/) {
		die "submitCheck: FATAL: Connection timed out for $host\n";
	} elsif ($@ =~ /Connection refused/) {
		die "submitCheck: FATAL: Connection refused for host $host\n";
	} elsif ($@) {
		die "submitCheck: FATAL: Unknown error: $@\n";
	}

	close( FH ) || die "submitCheck: FATAL: Unable to close socket: $!\n";
}




#----- Main ------------------------------------------------------------------

# DEBUG :comment-out nq-listunack.pl to test:
#my $out = [ 
#	"wdc|CRITICAL|u16u30|DW Retail.net DB Server|10.24.82.49|Blocker Status|screwed up beyond all description so that it will overflow the line",
#	"wdc|WARNING|u16u30|DW Retail.net DB Server|10.24.82.49|Disk Usage|/u01 87%",
#	"wdc|UNREACHABLE|mach1|PA FAS270 Filer|10.150.10.1|HOST|test" 
#];

my $out = [ `$Bin/nq-listunack.pl` ];

foreach (@$out) {
	my $tmprec = [ split( /\|/ ) ];
	$hashRec = {
		location      => $tmprec->[0],
		status        => $tmprec->[1],
		host_name     => $tmprec->[2],
		alias         => $tmprec->[3],
		ip            => $tmprec->[4],
		descr         => $tmprec->[5],
		plugin_output => $tmprec->[6],
		owner         => $tmprec->[7]
	};
	chomp $hashRec->{owner};
	push( @$listProbs, $hashRec );
}

print "\n";
print "-------------------------------------------------------------------------------\n";
print "       Unacknowledged Problems ".`date "+%m/%d/%Y %H:%M:%S"`;
print "-------------------------------------------------------------------------------\n";
my $i = 0;
foreach my $prob (@$listProbs) {
	printf( "%5d) %-72.72s\n       [%s] %s %-11.11s %-10.10s %-15.15s\n\n", 
		$i+1, 
		$listProbs->[$i]->{alias}." | ".$listProbs->[$i]->{descr}." | ".$listProbs->[$i]->{plugin_output},
		$listProbs->[$i]->{owner},
		$listProbs->[$i]->{location},
		$listProbs->[$i]->{status},
		$listProbs->[$i]->{host_name},
		$listProbs->[$i]->{ip}
	);
	$i++;
}
my $num_of_probs = scalar( @$listProbs );

print "\n";

# Don't prompt if list is empty:
if ($num_of_probs < 1) {
	print "       ** There are no unacknowledged problems at this time. **\n\n";
	exit (0);
}

# Prompt for index number of the problem to ack:
my $prob_to_ack = 0;
while ($prob_to_ack < 1 or $prob_to_ack > $num_of_probs) {
	print "Enter number to Acknowledge [quit]: ";
	$prob_to_ack = <STDIN>;
	chomp $prob_to_ack;

	if ($prob_to_ack eq "" or $prob_to_ack =~ /\D/) {
		print "\nExiting ... No action taken.\n\n";
		exit (0);
	}

	if ($prob_to_ack < 1 or $prob_to_ack > $num_of_probs) {
		print "\n    ** INVALID SELECTION **  Please select within range [1-$num_of_probs]\n\n";
	}

}

# Set the index of the selected problem:
my $prob_index = $prob_to_ack - 1;

# Prompt for user name:
my $username = "";
while (length( $username ) < 1 or length( $username ) > 40) {
 	print "                                   ----------------------------------------\n";
	print "Enter your name (CTRL-C to abort): ";
	$username = <STDIN>;
	chomp $username;

	if (length( $username ) > 40) {
		print "    ** Username width exceeded. **\n";
	}
}

# Get hostname script was run from:
my $hostname = lc( hostname() );

# Create the cmd string:
my $submit_cmd = "";
my $postfix = "$username;ACK from nq-ack.pl at $hostname";

my $sticky = 2;
if ($listProbs->[$prob_index]->{status} eq "WARNING") {
	$sticky = 1;
}

if ($listProbs->[$prob_index]->{descr} eq "HOST") {
	$submit_cmd = "ACKNOWLEDGE_HOST_PROBLEM;$listProbs->[$prob_index]->{host_name};1;1;0;$postfix";
} else {
	$submit_cmd = "ACKNOWLEDGE_SVC_PROBLEM;$listProbs->[$prob_index]->{host_name};$listProbs->[$prob_index]->{descr};$sticky;1;0;$postfix";
}

#print "DEBUG:\nsubmit_cmd = $submit_cmd\n";

# Get ip address to the nagios host:
my $nhost = "10.24.74.9";
if ($listProbs->[$prob_index]->{location} eq "sdc") {
	$nhost = "10.9.15.10";
}

submitCheck( $nhost, 80, \$submit_cmd );

# Print final output:
print "\n";
print "The following problem has been ACKNOWLEDGED:\n";
print "\n";
printf( "%5d) %-72.72s\n       %s %-11.11s %-10.10s %-15.15s\n\n", 
	$prob_to_ack, 
	$listProbs->[$prob_index]->{alias}." | ".$listProbs->[$prob_index]->{descr}." | ".$listProbs->[$prob_index]->{plugin_output},
	$listProbs->[$prob_index]->{location},
	$listProbs->[$prob_index]->{status},
	$listProbs->[$prob_index]->{host_name},
	$listProbs->[$prob_index]->{ip}
);

exit (0);
