#!/usr/bin/perl

########################################################################################################################
#
# Purpose:	Reads the Cache Hit % on NetApps (from the sysstat command)
#		The server this script is run from must be in /etc/hosts.equiv on the remote
#		NetApp.  On monitoring servers, this script will need to run via sudo, unless /etc/hosts.equiv
#		allows the nagios user to run commands via RSH.  That said, sudo is the preferred approach
# 		to minimize security exposure
#
# $Id: check_netapp_cache_hit.pl,v 1.1 2008/07/15 02:05:00 jkruse Exp $
# $Date: 2008/07/15 02:05:00 $
#
########################################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use IPC::Open3;

# Globals
my %args;
my @values;
my $optstr = 'I:t:';
my $usage = '-I <ip address> -t <timeout in seconds>';
my $rsh = '/usr/bin/rsh';

ArgParse::getArgs($optstr,2,\%args,\$usage);
runSysstat();

sub runSysstat {
	my $cmd = sprintf('%s %s sysstat -u -c 5 1',$rsh,$args{I});
	my ($reader,$writer);
	my $pid = open3($writer,$reader,$reader,$cmd);
	if ($pid) {
		my ($rin,$rout);
		my ($input,$data);
		vec($rin, fileno($reader), 1) = 1;
		my $i;
		for ($i = 0; $i < $args{t}; $i++) {
			if (select($rout=$rin,undef,undef,1)) {
				# If select returns true, it means there is data to be read.
				# Reset the timeout counter back to zero.
				# We only want to timeout after $timeout seconds of NO output
				# While this creates the possibility of this potentially running
				# forever (output comes in at a trickle every few seconds forever)
				# the liklihood of that happening is pretty remote.
				$i = 0;
				my $bytes_read = sysread($reader,$input,4096);
				if ($bytes_read) {
					$data.= $input;
				} else {
					# sysread returns 0 when at EOF
					last;
				}
			}
		}
		if ($i == $args{t}) {
			kill(9,$pid);
			print 'Command timed out';
			exit 3;
		} else {
			# Close the handles
			close($writer);
			close($reader);
			if ($data =~ /permission denied/i) {
				print 'RSH Permission Denied';
				exit 2;
			} elsif ($data =~ /No route to host/) {
				print 'Connection timed out';
				exit 2;
			} else {
				my @lines = split(/\n/,$data);
				my @hit_ratios;
				foreach my $line (@lines) {
					# Each line will have the following:
					# 96%   0%  -  67%
					# With the first value, (96% in this example) being
					# the cache hit %.  The - could either be a -,:, or
					# any letter
					if ($line =~ /(\d+)%\s+\d+%\s+[A-Za-z:-]\s+\d+%$/) {
						push(@hit_ratios,$1);
					}
				}
				if (scalar(@hit_ratios) > 0) {
					my $average;
					foreach my $val (@hit_ratios) {
						$average+= $val;
					}
					$average/= scalar(@hit_ratios);
					printf('%.2f%|%.2f',$average,$average);
					exit 0;
				} else {
					print 'Unable to parse NetApp Response';
					exit 3;
				}
			}
		}
	} else {
		# Command failed to start
		print $!;
		exit 3;
	}
}
