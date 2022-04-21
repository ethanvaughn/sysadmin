#!/usr/bin/perl

########################################################################################################################
#
# Name:		check_netapp_disk_utilization.pl
# Purpose:	Reads the disk utilization on NetApps (from the sysstat -u command)
#		The server this script is run from must be in /etc/hosts.equiv on the remote
#		NetApp.  On monitoring servers, this script will need to run via sudo, unless /etc/hosts.equiv
#		allows the nagios user to run commands via RSH.  That said, sudo is the preferred approach
# 		to minimize security exposure
#
# $Id: check_netapp_disk_utilization.pl,v 1.2 2008/04/15 12:28:01 jkruse Exp $
# $Date: 2008/04/15 12:28:01 $
#
########################################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use IO::Select;

# Globals
my %args;
my @values;
my $optstr = 'I:t:';
my $usage = '-I <ip address> -t <timeout in seconds>';

ArgParse::getArgs($optstr,2,\%args,\$usage);
getDiskUtil();

sub getDiskUtil {
	my $cmd = sprintf('rsh %s sysstat -u -c 1 5 2>&1|',$args{I});
	my $pid = open(CMD,$cmd) || die $!;
	my $s = IO::Select->new(\*CMD);
	unless($s->can_read($args{t})) {
		kill TERM => $pid;
		print 'Connection timed out';
		exit 2;
	}
	my ($output,$exit);
	while(<CMD>) {
		chomp;
		if (/Permission denied/) {
			$output = 'RSH Permission Denied';
			$exit = 2;
			last;
		}
		if (/No route to host/) {
			$output = 'Connection timed out';
			$exit = 2;
			last;
		}
		if (/(\d{1,3})%$/) {
			my $util = $1;
			if ($util > 100) {
				# Sometimes NetApps report Disk Util% > 100, which doesn't make any sense.  
				# They only do this when they are really under load, 
				# though, so when it happens, just store 100% for this sample
				$util = 100;
			}
			# Add this sample to the @values array (will be averaged later)
			push (@values,$util);
		}
	}
	close(CMD);
	if (!defined($exit)) {
		# If $exit has not yet been defined, it means there were no (known)
		# errors in the output from the command
		if (scalar(@values) > 0) {
			# Add up all of the values and average them
			my $sum = 0;
			foreach my $val (@values) {
				$sum+= $val;
			}
			my $average = $sum/scalar(@values);
			$output = sprintf('%d%|%d',$average,$average);
		} else {
			# This means that while there were no known errors in the output of the command,
			# no valid output was found, either.
			$output = 'Invalid output from device';
			$exit = 3;
		}
	}
	print $output;
	exit $exit;
}
