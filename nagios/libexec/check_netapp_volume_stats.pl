#!/usr/bin/perl

########################################################################################################################
#
# Name:		check_netapp_volume_stats
# Purpose:	Reads the average volume latency (r/w), bytes read, and bytes written per second
#		The server this script is run from must be in /etc/hosts.equiv on the remote
#		NetApp.  On monitoring servers, this script will need to run via sudo, unless /etc/hosts.equiv
#		allows the nagios user to run commands via RSH.  That said, sudo is the preferred approach
# 		to minimize security exposure
#
# $Id: check_netapp_volume_stats.pl,v 1.1 2008/08/04 21:17:22 jkruse Exp $
# $Date: 2008/08/04 21:17:22 $
#
########################################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use IPC::Open3;

# Globals
my %args;
my $rsh = 	'/usr/bin/rsh';
my $cmd =	'stats show -i 1 -n 10';
my $optstr =	'V:I:t:';
my $usage =	'-V <volume name> -I <ip address> -t <timeout in seconds>';

# Funtion-specific directives
my $volume;	# Volume to be queried 
my @values;	# Samples stored (as a hash ref) in this array

ArgParse::getArgs($optstr,3,\%args,\$usage);
runRSHCommand();

sub runRSHCommand {
	my $full_cmd = sprintf('%s %s %s volume:%s:avg_latency volume:%s:read_data volume:%s:write_data',$rsh,$args{I},$cmd,$args{V},$args{V},$args{V});
	my ($reader,$writer);
	my $pid = open3($writer,$reader,$reader,$full_cmd);
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
		# Did the above command timeout? (if $i == $timeout, it did)
		if ($i == $args{t}) {
			# Note that we don't care if we have partial output from the command --
			# if it timed out, it timed out, and that's the error that needs
			# to be raised.  There is a chance SOME output is in $data, but 
			# there's also a good chance that not ALL of it is there, in which
			# case it is useless anyway.  It's either all or nothing!
			kill(9,$pid);
			print 'Command timed out on host';
			exit 3;
		} else {
			# Command did not timeout: close it
			close($reader);
			close($writer);
			waitpid($pid,0);
			# Now check for errors
			if ($data =~ /exec of.*failed/) {
				printf('Unable to run %s',$rsh);
				exit 3;
			} elsif ($data =~ /Permission denied/) {
				print 'RSH permission denied';
				exit 3;
			} elsif ($data =~ /No instance/) {
				printf('Invalid volume name: %s',$args{V});
				exit 3;
			} else {
				my @lines = split(/\n/,$data);
				foreach my $line (@lines) {
					if ($line =~ /([-+]?[0-9]*\.?[0-9]+)\s+(\d+)\s+(\d+)$/) {
						my %h;
						$h{latency} = $1;
						$h{read_bytes} = $2;
						$h{write_bytes} = $3;
						push (@values,\%h);
					}
				}
				# All values extracted?
				if (scalar(@values) == 0) {
					print 'Unable to parse response';
					exit 3;
				} else {
					# We have values!
					# Now all the values have been extracted
					my ($latency,$read_bytes,$write_bytes);
					foreach my $sample (@values) {
						$latency+= $sample->{latency};
						$read_bytes+= $sample->{read_bytes};
						$write_bytes+= $sample->{write_bytes};
					}
					my $count = scalar(@values);
					$latency/= $count;
					$read_bytes/= $count;
					$write_bytes/= $count;
					printf	(	'Average Latency: %.2f ms  Throughput: %.2f MB/s Read %.2f MB/s Write|latency:%.2f read:%lu write:%lu',
							$latency,
							$read_bytes/1048576,
							$write_bytes/1048576,
							$latency,
							$read_bytes,
							$write_bytes
						);
					exit 0;
				}
			}
		}
	} else {
		# The command failed to start, this is weird and should never happen
		print 'Unable to run command: contact SA Team';
		exit 3;
	}
}
