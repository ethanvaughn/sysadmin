#!/usr/bin/perl

######################################################################################
#
# Purpose: Checks one or more sockets in parallel
# Author:  Jake Kruse
#
# $Id: check_remote_sockets_v2.pl,v 1.2 2009/07/08 23:21:38 evaughn Exp $
# $Date: 2009/07/08 23:21:38 $
#
######################################################################################

use lib '/u01/app/nagios/libexec/lib';


use IO::Socket::INET;
use threads;
use threads::shared;

use CheckLib;
use ArgParse;
use CheckBySSH;



#----- Globals ----------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required        = ( "ports", "services" );

my @ports :shared;
my @threads;

# Output variables
my $result;
my $return_code;




#----- main -------------------------------------------------------------------
ArgParse::getArgs( $optstr, 5, \%args, \$usage );

# Piece-together the name of the thresholds and default files from args:
my $serv_desc = CheckLib::normalizeServDesc( $args{S} );
my $threshold_file = "$basedir/$args{C}/$args{H}-$serv_desc";
if (! -e $threshold_file) {
	# No thresholds file, try default:
	$threshold_file = "$basedir/default/$serv_desc";
}

# Load threshold properties:
$thresholds = CheckLib::loadThresholds( $threshold_file, \@required );
if ($thresholds->{result} ne "0|OK") {
	($return_code,$result) = split( /\|/, $thresholds->{result} );
	print $result;
	exit $return_code;
}

my @tmp1 = split( /,/, $thresholds->{ports} );
my @tmp2 = split( /,/, $thresholds->{services} );

for (my $i = 0; $i < scalar(@tmp1); $i++) {
	my %port :shared;
	$port{port} = $tmp1[$i];
	$port{desc} = $tmp2[$i];
	push(@ports,\%port);
}


checkSockets();
parseOutput();



#---- checkSocket -------------------------------------------------------------
sub checkSocket {
	my ($port,$timeout) = @_;

	if (ref($port) ne 'HASH' || !defined($timeout)) {
		return;
	}

	# IO::Socket::INET provides a much friendlier interface to the select() system call,
	# which implements timeouts on file descriptors.  This is much more reliable (and re-entrant)
	# than OS signals, which are not.  So this is the preferred approach versus eval/die + alarm
	my $sock = IO::Socket::INET->new(
			PeerAddr => $args{I},
			PeerPort => $port->{port},
			Proto => 'tcp',
			Timeout => $timeout
			);
	# The constructor returns a new IO::Socket::INET object on success, and undef on failure
	# Since each thread is working on its own port hash ref, we do not need to deal with locking
	if ($sock) {
		# Connection good!
		# Close the socket
		$sock->shutdown(2);
		# Set status to 0
		$port->{status} = 0;
		$port->{message} = 'Listening';
	} else {
		if ($!) {
			my $error = $!;
			# Now check for errors
			if ($error =~ /Bad file descriptor/ || $error =~ /timed out/) {
				# bad file descriptor means there was a timeout, which shouldn't happen normally
				$port->{status} = 2;
				$port->{message} = 'Connection timed out';
			} elsif ($error =~ /Connection refused/) {
				# Connection refused throws a much more sane error than connection timeout
				$port->{status} = 2;
				$port->{message} = 'Connection Refused';
			} else {
				# If we get this, it's an uncaught exception
				$port->{status} = 3;
				$port->{message} = 'Unknown Error:',$error;
			}
		} else {
			# Somehow we got a null object back, and no error was set.  Alert SA team..
			# (This should never ever happen!)
			$port->{status} = 3;
			$port->{messages} = 'Null Object Error - contact SA Team';
		}
	}
}




#----- checkSockets -----------------------------------------------------------
sub checkSockets {
	# Depending on the number of ports, it could take a while to check them all.
	# Instead of checking them in series, check them in parallel instead
	# This means that this script will take, at most, only $args{t} seconds,
	# as opposed to $args{t}*Number of ports seconds.
	for (my $i = 0; $i < scalar(@ports); $i++) {
		my $thr = threads->create( \&checkSocket, $ports[$i], $args{t} );
		push( @threads, $thr );
	}
	# Now wait for each thread to finish
	for (my $i = 0; $i < scalar(@threads); $i++) {
		$threads[$i]->join();
	}
}




#----- parseOutput ------------------------------------------------------------
sub parseOutput {
	$return_code = 0;
	for (my $i = 0; $i < scalar(@ports); $i++) {
		my $port = $ports[$i];
		# 2 is critical, 3 is unknown.  If any port is unknown, it should 'outrank'
		# criticals.  Plus, this will also initially set return_code if everything was OK otherwise
		# Granted, the only circumstance where an unknown occurs is an untrapped error in the eval
		# in checkSockets.  But this does apply for criticals, so maybe it's worth doing
		if ($port->{status} > $return_code) {
			$return_code = $port->{status};
		}
		if ($port->{status} != 0) {
			$output.= sprintf('%s(%d):%s,',$port->{desc},$port->{port},$port->{message});
		}
	}
	if ($output) {
		# Remove the trailing comma
		chop($output);
	} else {
		# If output was never defined, it means all the ports are listening
		$output = 'All Ports Listening';
	}
	print $output;
	exit $return_code;
}
