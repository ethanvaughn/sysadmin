#!/usr/bin/perl

###########################################################################
#
# Purpose:	Checks filesystem disk space free
#
# $Id: check_remote_filesize.pl,v 1.2 2008/11/07 00:06:54 evaughn Exp $
# $Date: 2008/11/07 00:06:54 $
#
# Author: Ethan Vaughn
#
###########################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;


#----- Globals ---------------------------------------------------------------
my %args; # Where command-line arguments get stored
my $cmd; # Will be built in readThresholds below..
my $optstr = 'I:H:C:t:';
my $basedir = '/u01/home/nagios/monitoring';
my $suffix = 'Filesize';
my $usage = '-H <hostname> -C <customer abbrev> -I <ip address> -t (optional)<timeout in seconds>',

# Output variables
my ($output,$return_code);

# Function-Specific variables
my %thresholds;



#----- Main ------------------------------------------------------------------
ArgParse::getArgs( $optstr, 4, \%args, \$usage );
readThresholds();
CheckBySSH::queryHost( $cmd, $args{I}, $args{t} );
parseOutput();



#----- readThresholds --------------------------------------------------------
sub readThresholds {
	my $dirlist;
	my $result = open( FILE, "$basedir/$args{C}/$args{H}-$suffix" );
	if ($result) {
		while (<FILE>) {
			next if /^#/;
			chomp;
			my ($key, $value) = split( /:/, $_ );
			$thresholds{$key} = $value;
#DEBUG
#print "[$key] = $thresholds{$key}\n";

		}
		close( FILE );

		if (!defined( $thresholds{ 'dir' } )) {
			printf( 'Missing "dir" key from thresholds. Verify syntax of %s/%s-%s', $args{C}, $args{H}, $suffix );
			exit 3;
		}
		if (!defined( $thresholds{ 'warn' } ) && !defined( $thresholds{ 'crit' } )) {
			printf( 'Missing warn and crit keys from thresholds. Verify syntax of %s/%s-%s', $args{C}, $args{H}, $suffix );
			exit 3;
		}
		if (defined( $thresholds{ 'warn' } ) && $thresholds{ 'warn' } < 1) {
			printf( 'The "warn" key must be numeric > 0. Verify syntax of %s/%s-%s', $args{C}, $args{H}, $suffix );
			exit 3;
		}
		if (defined( $thresholds{ 'crit' } ) && $thresholds{ 'crit' } < 1) {
			printf( 'The "crit" key must be numeric > 0. Verify syntax of %s/%s-%s', $args{C}, $args{H}, $suffix );
			exit 3;
		}

		# Not fatal. Just 
		if (defined( $thresholds{ 'crit' } ) && defined( $thresholds{ 'warn' } )) {
			if ($thresholds{ 'crit' } < $thresholds{ 'warn' }) {
				delete( $thresholds{ 'warn' } );
			}
		}
		
#DEBUG
#foreach my $key (keys(%thresholds)) {
#	print $key . "\n";
#}

		# Build the command ... 
		$cmd = 'find ' . $thresholds{ 'dir' } . ' -type f -ls -maxdepth 1 | tr -s " " | cut -d " " -f 7,11' . "\n";
	} else {
		# If result = undef, it means the file couldn't be found
		printf( '%s/%s-%s not found', $args{C}, $args{H}, $suffix );
		exit 3;
	}
}



#----- parseOutput -----------------------------------------------------------
sub parseOutput {
	$return_code = 0;
	my $CONST = 1048576;
	my $warns;
	my $warn_cnt=0;
	my $crits;
	my $crit_cnt=0;

	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}

	foreach my $line (@{ $CheckBySSH::query_results{output} }) {
		my @values = split( / /, $line );

#DEBUG
#print $line . "\n";

		# Thresholds size is in Mb, but size retrieved is in bytes. Div by
		# CONST to compare:
		my $size_mb = ($values[0] / $CONST);
		if (defined( $thresholds{'crit'} ) && $size_mb >= $thresholds{'crit'}) {
			$crit_cnt++;
#DEBUG
#print 'CRIT: ' . $size_mb . ' Mb ' . $values[1] . "\n";
			$crits .= " $values[1]";
			$return_code = 2;
		} elsif (defined( $thresholds{'warn'} ) && $size_mb >= $thresholds{ 'warn' }) {
			$warn_cnt++;
#DEBUG
#print 'WARN: ' . $size_mb . ' Mb ' . $values[1] . "\n";
			$warns .= " $values[1]";
			$return_code = 1 if ($return_code != 2);
		}
	}

	if ($return_code > 0) {
		my $warn_msg;
		my $crit_msg;
		$warn_msg = sprintf( '[WARN:%s Mb %s files]: %s', $thresholds{'warn'}, $warn_cnt, $warns ) if ($warn_cnt);
		$crit_msg = sprintf( '[CRITICAL:%s Mb %s files]: %s', $thresholds{'crit'}, $crit_cnt, $crits ) if ($crit_cnt);
		$output = sprintf( 'Filesize threshold exceeded: %s %s', $warn_msg, $crit_msg );
	} else {
		$output = 'File sizes within limits.';
	}

	# Done, just spit out the output and use the exit code defined in return_code
	print $output;
	exit $return_code;
}
