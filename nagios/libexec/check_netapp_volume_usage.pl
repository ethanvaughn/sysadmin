#!/usr/bin/perl

######################################################################################################
#
# Purpose:		Report total disk space used/allocated for one or more volumes
#			on one or more NetApps
#
# $Id: check_netapp_volume_usage.pl,v 1.1 2008/03/05 02:58:10 jkruse Exp $
# $Date: 2008/03/05 02:58:10 $
#
######################################################################################################

use strict;
use Getopt::Std;

# Global vals
my @args = 		qw(I H S C); # Command-line arguments to parse (-I, -H...)
my $basedir = 		'/u01/home/nagios/monitoring'; # Where config files are stored
my %args;		# Command-line arguments will be stored here
my $suffix;		# Will be built from cmd-line argument -S to determine the suffix on the filename to be read

# Commands
my $snmp_cmd = '/usr/bin/snmptable'; # Our friend that does all the hard work whose output we gleefully parse

# Command Helpers
my $netapp_mib = '/u01/app/nagios/libexec/lib/netapp.mib'; # NetApp MIB: used to get the right OIDs

# Function-specifc data
my %volumes;		# Each volume read from the config file will go here
my @hosts;		# Each of the hosts to query (read from command line) will eventually go here

getArgs();
validateArgs();
readThresholds();
queryNetApps();
addResults();

sub validateArgs {
	my @valid_hosts;
	# Validate that each host is a real, valid IP address
	foreach my $host (@hosts) {
		if ($host =~/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
			# Add this validated host to @valid_hosts
			push(@valid_hosts,$host);
		}
	}
	if (scalar(@valid_hosts) == 0) {
		# if @valid_hosts is empty, tell the user they are a moron and need to learn
		# how to type in an IP address
		usage();
	} else {
		# Now set @hosts to @valid_hosts (our cleaned up, validated version)
		@hosts = @valid_hosts;
		return;
	}
}

sub readThresholds {
	# This function is for reading the config in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/; # cheap and easy way to allow for comments
			my @tokens = split(/,/);
			# For each volume that is to be queried, add it to the %volumes hash.
			# Set the key to the name of the volume (i.e, jposluns) and the value to
			# an anonymous hash we'll use later on
			foreach my $token (@tokens) {
				$volumes{$token} = {};
			}
		}
		close(FILE);
		if (scalar(keys(%volumes)) == 0) {
			print 'At least one volume is required';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		printf('%s/%s-%s not found',$args{C},$args{H},$suffix);
		exit 3;
	}
}

sub queryNetApps {
	# This function technically isn't necessary.  It just makes it a bit clearer what's going on.  queryNetApp($host) deals with
	# querying a single netapp, and all the logic for querying and parsing those values is encapsulated there.  To shorten
	# that function down, it's called here for each netapp in @hosts.  Maybe this is overkill.  And maybe you're a gaywad too.
	# OK, so that was harsh.  No one will read these comments anyway. :)
	foreach my $host (@hosts) {
		#print "Querying $host\n";
		queryNetApp($host);
	}
}

sub queryNetApp {
	# Since this script is used to provide purely informational data, we don't sound the alarm if the netapp
	# being queried fails to respond.
	my $host = shift;
	my $cmd = sprintf('%s -v 1 -c public  -C Hf \: -m %s %s NETWORK-APPLIANCE-MIB::dfTable 2>&1|',$snmp_cmd,$netapp_mib,$host);
	#print $cmd,"\n";
	my $pid = open(CMD,$cmd);
	if ($pid) {
		while(<CMD>) {
			# If the string contains any type of timeout, give up and do not pass
			# go, just get out of here and give up
			if (/^Timeout/i) {
				last;
			}
			# Output from snmptable looks kind of like the following:
			#26:"/vol/somevol":0:457280:0:0:0:0:0:"/vol/somevol":1383533:3859:11068300:0:0:0:457280:3:-457280:mounted:invalid:0:flexibleVolume
			# Not terribly intuitive, but there are some nuggets here:
			# Field 2 is the volume name
			# Fields 13 and 14 are the amount (in KB) allocated, expressed as 64-bit highpart/lowpart
			# Fields 15 and 16 are the amount (in KB) used, expressed as 64-bit highpart/lowpart
			my @values = split(/:/);
			if ($values[1] =~ /"\/vol\/(\w+)\/"/) {
				# If the above regex matched, then this is a volume (not a snapshot)
				if (exists($volumes{$1})) {
					# If $1 (the name of the volume) is in our list, mark it as found (by setting found = 1)
					# Then calculate the amount used and allocated
					$volumes{$1}->{found} = 1;
					$volumes{$1}->{allocated} = convert32to64($values[13],$values[14]);
					$volumes{$1}->{used} = convert32to64($values[15],$values[16]);
				}
			}
		}
		close(CMD);
	} else {
		print 'Unable to execute command: ',$!;	
		exit 3;
	}
}

sub convert32to64 {
	# Contrary to what might be obvious, we need to do 64-bit arithmetic here on 32-bit values.
	# The MIB gives some nice easy 32-bit counters for disk space usage, but those break when disk usage is >
	# than 2 TB (maximum of a 32-bit signed int).  However, the MIB does provide highpart/lowpart values of the
	# 64-bit values.  The formula is as follows for taking two 32-bit values and obtaining the 64-bit value:
	# 
	# 1) if $lowpart <= 0, add 1 to $highpart
	# 2) multiply highpart * 2^32, then add to lowpart
	# 3) This is the value in KB.  Divide by 1048576 to convert to GB
	my ($highpart,$lowpart) = @_;
	if ($lowpart <= 0) {
		$highpart++;
	}
	return (($highpart * 4294967296) + $lowpart)/1048576;
}

sub addResults {
	# Sum up all the values for each volume into used_total and allocated_total, respectively
	# Note that we're no longer interested in volume names (the keys of the %volumes hash)
	# so we only iterate the values of the hash
	my ($used_total,$allocated_total);
	foreach my $volume (values(%volumes)) {
		if (ref($volume) eq 'HASH') {
			if (exists($volume->{found})) {
				$used_total+= $volume->{used};
				$allocated_total+= $volume->{allocated};
			}
		}
	}
	# At last, at last, we output the values to STDOUT.  Note that if no valid volumes
	# were found (in other words, the config file read in didn't contain any that matched what
	# is actually on these netapps), one could expect to see 0 used, 0 allocated.
	#
	# BUT, so as to not mess up the graphs that are generated by this output with zeros (that would throw
	# off the averages) we check and see if at least used_total > 0 or allocated_total > 0.
	# If it's a new customer, it's possible used_total COULD be zero (unlikely, but possible) but allocated_total
	# should never be zero unless you are a moron and typed in the wrong volume names that don't actually exist
	# on this filer.  Anyway, to prevent zeros from being graphed, we supply NO performance data when we have no valid
	# used_total or allocated_total.  Better to plot an unknown (so as to not mess with the averages)
	# than a zero.
	#
	# Lastly, as you can see in the queryNetapp($host) function, we don't do anything
	# special if the netapp can't be contacted.  This check is 100% informational, so don't spend any
	# time trying to figure out why snmptable couldn't talk to the NetApp in question
	if ($used_total > 0 || $allocated_total > 0) {
		printf('%0.2f GB Used, %0.2f GB Allocated|used:%0.2f allocated:%0.2f',$used_total,$allocated_total,$used_total,$allocated_total);
		exit 0;
	} else {
		print 'Unable to parse NetApp response';
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
		# It's entirely supported to enter just one IP address (for non-clustered environments, for example)
		# So, make sure that at least one IP address was selected.  Note that we'll test later
		# to make sure it was actually a valid IP address (in validateArgs)
		@hosts = split(/,/,$args{I});
		if (scalar(@hosts) < 1) {
			usage();
		}
	} else {
		usage();
	}
}

sub usage {
	# Customize as appropriate here.  First two lines are boiler plate, third line is the one to change (to reflect command-line arguments)
	print 	'Usage: ',
		$0,
		' -H <hostname> -S "Service Name" -C <customer abbrev> -I <ip,ip,ip> (one or more IP address separated by commas)',
		"\n";
	exit 3;
}
