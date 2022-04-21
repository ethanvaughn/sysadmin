#!/usr/bin/perl

###########################################################################################################
#
# Purpose: 		Tracks deltas of socket connections for the specified source port
#			Uses netstat to examine the source port of the remote connection,
#			which will change if a client has disconnected and reconnected
#			since the last time the script executed
#
# $Id: check_remote_socket_delta_v2.pl,v 1.3 2009/11/13 16:32:43 evaughn Exp $
# $Date: 2009/11/13 16:32:43 $
#
###########################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;

use CheckLib;
use ArgParse;
use CheckBySSH;

# ----- Globals --------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd	= '/bin/netstat -n --numeric-ports --tcp';
my $basedir = '/u01/home/nagios/monitoring';
my $optstr = 'I:H:C:S:t:';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"';
my $thresholds;     # HashRef of properties from the threshold file.
my @required = ( 'port' );

my $tmpdir = '/u01/app/nagios/tmp'; # Where to store the file containing the list of connections
my $tmp_filename;	# Filename used for readings on this service

# Output variables
my $result;
my $return_code;

# Function-Specific variables
my (%current,%previous);
my ($gained_count,$lost_count,$current_count);




#----- compareValues ----------------------------------------------------------
sub compareValues {
	# Any key in $current and not in $previous represents a new connection (gain)
	foreach my $con (keys(%current)) {
		if (!exists($previous{$con})) {
			$gained_count++;
		}
	}
	# Any key in %previous and not in %present represents a closed connection (lost)
	foreach my $con (keys(%previous)) {
		if (!exists($current{$con})) {
			$lost_count++;
		}
	}
}




#----- writeHashToFile --------------------------------------------------------
sub writeHashToFile {
	my ($file,$data) = @_;
	my $retval = 0;
	my $result = open(OUT,'>'.$file);
	if ($result) {
		while (my ($key,$val) = each(%$data)) {
			print OUT $key,"\n";
		}
		close(OUT);
		$retval = 1;
	} else {
		print "Unable to open $file for write, contact SA Team";
		exit 3;
	}
	return $retval;
}




#----- Main ------------------------------------------------------------------
ArgParse::getArgs( $optstr, 5, \%args, \$usage );

# Piece-together the name of the thresholds and default files from args:
my $serv_desc = CheckLib::normalizeServDesc( $args{S} );
my $threshold_file = "$basedir/$args{C}/$args{H}-$serv_desc";
if (! -e $threshold_file) {
	# No thresholds file, try default:
	$threshold_file = "$basedir/default/$serv_desc";
}

$tmp_filename = $args{H} . '-' . $serv_desc;

# Load threshold properties:
$thresholds = CheckLib::loadThresholds( $threshold_file, \@required );
if ($thresholds->{result} ne "0|OK") {
	($return_code,$result) = split( /\|/, $thresholds->{result} );
	print $result;
	exit $return_code;
}

$cmd .= '| grep ' . $thresholds->{ports};

# Run the remote command and parse the output.
CheckBySSH::queryHost( $cmd, $args{I}, $args{t}, $thresholds->{username} );
if (exists($CheckBySSH::query_results{status_code})) {
	print $CheckBySSH::query_results{output};
	exit $CheckBySSH::query_results{status_code};
}

foreach my $line (@{$CheckBySSH::query_results{output}}) {
	my @values = split(/\s+/,$line);
	if ($values[3] =~ /:$thresholds->{port}$/ && $values[4] =~ /^(.*:\d+)/) {
		$current{$1} = 1;
		$current_count++;
	}
}

my $output_format = 'Gained: %d Lost: %d Current: %d|gained:%d lost:%d current:%d';
my $full_filename = $tmpdir.'/'.$tmp_filename;
if (-e $full_filename) {
	my $result = open(IN,$full_filename);
	if ($result) {
		while(<IN>) {
			chomp;
			if (/(.*:\d+)/) {
				$previous{$1} = 1;
			}
		}
		close( IN );
		# Send the current hash back to the file we just read
		writeHashToFile( $full_filename, \%current );
		# Now compare
		compareValues();
		# If either $gained_count or $lost_count are are over 90% of $current_count, discard the reading,
		# erase the previous value, and basically reset.  Better to have a gap in the graph
		# than a huge spike, which throws off all of the averages
		if ($current_count > 0) {
			if ($gained_count/$current_count >= 0.9 || $lost_count/$current_count >= 0.9) {
				unlink($full_filename);
				$result = 'Change in gained/lost connections exceeded 90%, discarding';
				$return_code = 3;
			}
		}
	} else {
		$result = sprintf('Unable to open %s for read, contact SA Team',$full_filename);
		$return_code = 3;
	}
} else {
	if (writeHashToFile($full_filename,\%current)) {
		$output_format = '(No Previous Value) ' . $output_format;
	}
}
# If $result has not yet been defined, then everything is OK.  Otherwise it has
# already been set with an error that needs to be displayed
if (!$result) {
	$result = sprintf( $output_format, $gained_count, $lost_count, $current_count, $gained_count, $lost_count, $current_count );
	if ($thresholds->{warning} > 0 && $thresholds->{critical} > 0) {
		if ($gained_count >= $thresholds->{warning} || $lost_count >= $thresholds->{warning}) {
			if ($gained_count >= $thresholds->{critical} || $lost_count >= $thresholds->{critical}) {
				$return_code = 2;
			} else {
				$return_code = 1;
			}
		} else {
			$return_code = 0;
		}
	} else {
		$return_code = 0;
	}
}


print $result;
exit $return_code;