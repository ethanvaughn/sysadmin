#!/usr/bin/perl

############################################################################################
#
# Purpose:	Informational use only; reports NFS/iSCSI IOPS
#
# $Id: check_netapp_iops.pl,v 1.1 2008/06/02 21:00:47 jkruse Exp $
# $Date: 2008/06/02 21:00:47 $
#
############################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;

############################### Configuration Globals ######################################

# Commands
my $snmpget = 		'/usr/bin/snmpget';

# OIDs
my $nfs_high_oid =	'.1.3.6.1.4.1.789.1.2.2.5.0';
my $nfs_low_oid = 	'.1.3.6.1.4.1.789.1.2.2.6.0';
my $iscsi_high_oid = 	'.1.3.6.1.4.1.789.1.17.11.0';
my $iscsi_low_oid = 	'.1.3.6.1.4.1.789.1.17.12.0';
my $community =		'public'; # SNMP Community
my $version = 		1; # SNMP version

my $optstr = 		'I:'; # Only need IP address as an argument
my $usage =		'-I <ip address>',

############################### Global Variables ##########################################

my %args; 		# Command-line arguments go here
my $cmd;		# Will be built by queryLoop
my $interval =		10;

############################### Main Body #################################################

ArgParse::getArgs($optstr,2,\%args,\$usage); # Note using 2: ArgParse supplies a timeout
queryLoop();

############################### Functions #################################################


sub queryLoop {
	$cmd = sprintf		(
				'%s -v %s -c %s %s %s %s %s %s 2>&1|',
				$snmpget,
				$version,
				$community,
				$args{I},
				$nfs_high_oid,
				$nfs_low_oid,
				$iscsi_high_oid,
				$iscsi_low_oid
				);
	my ($nfs_1,$iscsi_1) = queryNetapp();
	sleep($interval);
	my ($nfs_2,$iscsi_2) = queryNetapp();
	my $display_nfs = ($nfs_2 - $nfs_1)/$interval;
	my $display_iscsi = ($iscsi_2 - $iscsi_1)/$interval;
	printf('NFS IOPS: %d/s, iSCSI IOPS: %d/s|nfs:%s iscsi:%s',$display_nfs,$display_iscsi,$nfs_2,$iscsi_2);
	exit 0;
}

sub queryNetapp {
	# OK, so maybe this isn't the best use of sprintf.
	#print $cmd,"\n"; # Useful for debugging to see what monster command sprintf generates
	my $result = open(CMD,$cmd);
	if (!$result) {
		printf('Unable to run %s:%s',$snmpget,$!);
		exit 3;
	} else {
		my @values;
		while(<CMD>) {
			chomp;
			if (/Counter32: (\d+)/) {
				push(@values,$1);
			} 
		}
		close(CMD);
		my $status = $?;
		$status >>= 8;
		if ($status != 0) {
			printf('Connection timed out querying %s',$args{I});
			exit 3;
		} else {
			if (scalar(@values) == 4) {
				# Indicies 0,1 are nfs high,low
				# Indicies 1,2 are iscsi high,low
				# Need to convert both of these into 64-bit integers
				my $nfs_iops = convert32to64($values[0],$values[1]);
				my $iscsi_iops = convert32to64($values[2],$values[3]); 
				return $nfs_iops,$iscsi_iops;
			} else {
				print 'Unable to parse SNMP response';
				exit 3;
			}
		}
	}
}

sub convert32to64 {
	my ($high,$low) = @_;
	if ($low <= 0) {
		$high++;
	}
	return (($high*4294967296) + $low);
}
