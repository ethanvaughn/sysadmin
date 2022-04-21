#!/usr/bin/perl

##################################################################################
#
# Name:			check_remote_linux_cluster_fs
# Purpose		Checks the given filesystemsand submits the status 
#			of said FS via passive check to this monitoring server
#
# $Id: check_remote_linux_cluster_fs.pl,v 1.3 2008/02/05 03:43:24 jkruse Exp $
# $Date: 2008/02/05 03:43:24 $
#
##################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use CheckBySSH;
use Getopt::Std;
use Fcntl ':flock';

###############################################################################
#
# IMPORTANT NOTES ON HOW THIS WORKS
#
# This script is quite different from other monitoring scripts
# which traditionally read in a parameter file, do some kind of
# query operation, and then spit out the results.  This script
# is for checking shared filesystems (typically NFS mounts)
# in cluster environments.  Here's how it works:
#
# 1) Reads in the parameter file in the standard naming syntax
#	(i.e, hostname-service_name), where hostname
#	is the sname of THIS cluster node
# 2) Looks for two directives in the parameter file
#	cluster_host: name of the cluster (i.e, pc-racdb)
#	cluster_service: usually Disk Usage, but not required
# 3) Opens the parameter file for $args{C}/$cluster_host-$cluster_service
#	and reads in those thresholds
# 4) Queries this cluster node, looking at the filesystems specified in
#	step 3.
# 5) If the remote command did not time out, parse the results.  If
#	the command did timeout, exit with that status. 
# 6) Submit the parsed results and status code from those results
#	to the Nagios FIFO
# 7) Exit with OK status (cluster disk checks are working) if we 
#	make it this far
#
###############################################################################


# Globals and configuration vars
my %args; # Where command-line arguments get stored
my $cmd = 'df -h -P'; # Command to run, arguments and all (see below for more details on this)
my @args = qw(S I H C t); # Command-line arguments to parse
my $basedir = '/u01/home/nagios/monitoring';
my $suffix; # Determined on the fly

# Output variables
my ($output,$return_code);

# Function-Specific variables
my %thresholds;
my ($cluster_host,$cluster_service,$cluster_output,$cluster_return_code);
my $nagios = '/u01/app/nagios/var/rw/nagios.cmd';

# Main Body
getArgs();
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t});
parseOutput();

sub parseOutput {
	# All the parsing on the output (to determine things like warning/critical, etc.) should be done here, and not
	# in queryHost().  Since queryHost() is time-sensitive (all of the code in the eval block must be completed before the signal is caught)
	# the amount of data processing should be kept to a minimum
	# This routine will vary considerably from script to script!

	my %partitions;
	my $match_count = 0;
	if (exists($CheckBySSH::query_results{status_code})) {
		print $CheckBySSH::query_results{output};
		exit $CheckBySSH::query_results{status_code};
	}

	# The remote command did NOT timeout.  So set the output for THIS check (not the cluster check)
	$output = 'All Filesystems Responding';
	$return_code = 0;

	# From here on out we're preparing the output of the status check on the cluster host, not the server
	# this check was originally run against.
	foreach my $line (@{$CheckBySSH::query_results{output}}) {
		next if $line =~ /^Filesystem/;
		chomp($line);
		my @values = reverse(split(/\s+/,$line));
		if (exists($thresholds{$values[0]})) {
			$values[1] =~ s/\D//;
			my $percent_free = 100-$values[1];
			# The value of each key in the thresholds hash is a hash reference
			# which is why  this {}->{} notation is used
			if ($percent_free <= $thresholds{$values[0]}->{critical}) {
				# Critcal
				if (!$cluster_return_code) {
					$cluster_return_code = 2;
				} elsif ($cluster_return_code == 1) {
					$cluster_return_code = 2;
					$output.= ',';
				}
				$cluster_output.= "$values[0] - $percent_free% free ($values[2]) ";
			} elsif ($percent_free <= $thresholds{$values[0]}->{warning}) {
				# Warning
				if (!$cluster_return_code) {
					$cluster_return_code = 1;
				} else {
					$cluster_output.= ',';
				}
				$cluster_output.= "$values[0] - $percent_free% free ($values[2]) ";
			}
			# Whether the partition in question is OK, warning, or critical, it matched, therefore 
			# we increment match_count, which is used later to tell if we have any partitions that don't
			# match from our thresholds file
			$match_count++;
			$thresholds{$values[0]}->{status} = 1; # Indicate this partition has been matched
		}
	}
	if ($match_count != scalar(keys(%thresholds))) {
		# One or more partitions in the thresholds file couldn't be found
		# Regardless of what the status is of the partitions that matched, 
		# only output what couldn't be found (since the return code is set to 3
		# So iterate the thresholds hash, and look for any partition whose status != 1
		while (my ($partition,$data) = each(%thresholds)) {
			if ($data->{status} != 1) {
				if (!$cluster_output) {
					$cluster_output = 'UNKNOWN: '.$partition.' missing';
					$cluster_return_code = 3;
				} else {
					$cluster_output.= ','.$partition.' missing';
				}
			}
		}
	} elsif (!$cluster_output) {
		# If output hasn't been defined yet, then it means everything is OK
		$cluster_output = 'All Partitions OK';
		$cluster_return_code = 0;
	}

	# Now we have all the information for this cluster check: submit it to the Nagios FIFO
	# We do this in an eval using signals and alarm to prevent timeouts on submitting to the FIFO

	my $check = sprintf('[%lu] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s%s',time(),$cluster_host,$cluster_service,$cluster_return_code,$cluster_output,"\n");
	eval {
		local $SIG{ALRM} = sub { die 'Connection timed out' };
		alarm(5);
		open(FH,">$nagios") || die "Unable to open $nagios: $!";
		# FIFOs on Linux can't hold a lot of data.  To keep from overloading the FIFO, we do
		# an exlcusive lock so that the other processes writing to this FIFO will have to queue up
		# so as to prevent buffer overflows.  (Which are very easy to cause with FIFOs!)
		flock(FH,LOCK_EX) || die "Unable to lock: $!";
		syswrite(FH,$check);
		flock(FH,LOCK_UN);
		close(FH);
		# Diagnostics during testing
		#print $check;
		alarm(0);
	};

	# After all is said and done, just spit out the output and use the exit code defined in return_code
	# This output is for THIS host, not the cluster host (cluster host was submitted above via passive check)

	print $output;
	exit $return_code;
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result;
	$result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		my $arg_count = 0;
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/cluster_host:(.*)$/) {
				$cluster_host = $1;
				$arg_count++;
				next;
			}
			if (/cluster_service:(.*)$/) {
				$cluster_service = $1;
				$arg_count++;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 2) {
			print 'UNKNOWN: cluster_host and cluster_service are required directives,verify syntax of '.$args{C}.'/'.$args{H}.'-'.$suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
                print 'UNKNOWN: ',$args{C},'/',$args{H},'-',$suffix,' not found';
                exit 3;
	}
	my $cluster_service_suffix = $cluster_service;
	$cluster_service_suffix =~ s/\s/_/g;
	$result = open(FILE,"$basedir/$args{C}/$cluster_host-$cluster_service_suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			my @values = split(/\s+/);
			# Validating tokens, and check that warn (1) > than crit (2)
			if ($values[0] =~ /^\/$|^\/\w/ && $values[1] =~ /^\d+$/ && $values[2] =~ /^\d+$/ && $values[1] > $values[2]) {
				# The data structure being created here is a hash with two keys: warning,critical
				# This hash is stuffed in the thresholds hash, keyed off the name of the partition.
				# Think of it this way:
				# thresholds{partition name}->{hash of warning and critical thresholds}
				my %partition;
				$partition{warning} = $values[1];
				$partition{critical} = $values[2];
				$thresholds{$values[0]} = \%partition;
			}
		}
		close(FILE);
		if (scalar(keys(%thresholds)) < 1) {
			# This means we didn't get any valid partitions to check
			print 'UNKNOWN: No valid cluster partitions found in ',$args{C},'/',$cluster_host,'-',$cluster_service_suffix;
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print 'UNKNOWN: ',$args{C},'/',$cluster_host,'-',$cluster_service,' not found';
		exit 3;
	}
}

sub getArgs {
	# This is the basic code here.  It doesn't do any validation
	# other than a parameter was supplied to each of the arguments.
	# Customize as appropriate to add additional validators
	# If, for example, command-line arguments affect the parameters passed to the remote
	# command, append them to $cmd here (assuming they validate, of course)
	my $validated_args = 0;
	my $optstr = join(':',@args);
	$optstr.= ':'; # join misses the very last colon
	getopts($optstr,\%args);
	foreach my $arg (@args) {
		if(exists($args{$arg})) {
			$validated_args++;
		}
	}
	if ($validated_args == scalar(@args)) {
		return;
	} else {
		usage();
	}
}

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Description"',
		"\n";
	exit 3;
}
