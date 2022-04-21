#!/usr/bin/perl

use strict;
use Getopt::Std;

############################################################################################
#
# Purpose:	checks the given Cisco PIX/ASA/Switch interface for up/down status
#
# $Id: check_cisco_interface.pl,v 1.8 2008/02/06 21:48:24 jkruse Exp $
# $Date: 2008/02/06 21:48:24 $
#
############################################################################################

############################### Configuration Globals ######################################

# Commands
my $snmpget = 		'/usr/bin/snmpget';
my $snmpwalk = 		'/usr/bin/snmpwalk';

# OIDs
my $in_32 = 		'IF-MIB::ifInOctets'; # Traffic in (32-bit)
my $out_32 = 		'IF-MIB::ifOutOctets'; # Traffic out (32-bit)
my $in_64 = 		'IF-MIB::ifHCInOctets'; # Traffic in (64-bit) (Required for GB interfaces)
my $out_64 = 		'IF-MIB::ifHCOutOctets'; # Traffic out (64-bit) (Required for GB interfaces)
my $status =		'IF-MIB::ifOperStatus'; # Interface Up/Down
my $uptime =		'IF-MIB::ifLastChange'; # Interface Uptime
my $mib_name = 		'IF-MIB::ifName'; # Interface description (Switches)
my $mib_desc = 		'IF-MIB::ifDescr'; # Interface description (PIX firewalls)
my $interface_alias = 	'IF-MIB::ifAlias'; # User-supplied desc on switches (unused)
my $community =		'public'; # SNMP Community, with default value
my $version = 		1; # SNMP version, with default value
my $in = 		$in_32; # Counter OID to use (default is 32-bit);
my $out =		$out_32; # Counter OID to use (default is 32-bit);

my $basedir = 		'/u01/home/nagios/monitoring'; # Where config files are stored
#my $basedir = 		'/u01/home/nagios/stage'; # Where config files are stored (TESTING)
my @args = 		qw(I H S C); # Command-line arguments to parse (-I, -H...)

############################### Global Variables ##########################################

my %args; 		# Command-line arguments go here
my $suffix;		# Suffix (Service name)
my %config;		# Variables read in from config file
my $index;		# SNMP Index (interface) to query
my $mib_to_query;	# the MIB to use ($mib_name, $mib_desc, etc.)

############################### Main Body #################################################

getArgs();
readThresholds();
findInterfaceIndex();
queryInterface();

############################### Functions #################################################


sub queryInterface {
	# OK, so maybe this isn't the best use of sprintf.  From the SNMP Index of the
	# interface found in the last query, queries all of the OIDs associated with
	# this interface, specifically throughput and uptime.  Alias, or the user-
	# supplied description on the interface, is stored as well, but not used
	# at the present.  Maybe it'll be interesting in the future.
	my $cmd = sprintf
				(
				'%s -v %s -c %s %s %s %s %s %s %s 2>&1|',
				$snmpget,
				$version,
				$community,
				$args{I},
				$in.'.'.$index,
				$out.'.'.$index,
				$status.'.'.$index,
				$uptime.'.'.$index,
				$mib_to_query.'.'.$index
				);
	#print $cmd,"\n"; # Useful for debugging to see what monster command sprintf generates
	my $result = open(CMD,$cmd);
	if (!$result) {
		printf('Unable to run %s:%s',$snmpget,$!);
		exit 3;
	} else {
		my ($in_bytes,$out_bytes,$if_status,$if_uptime,$if_desc,$pcount);
		while(<CMD>) {
			chomp;
			if (/InOctets.*:\s+(\d+)$/) {
				$in_bytes = $1;
				$pcount++;	
				next;
			} 
			if (/OutOctets.*:\s+(\d+)$/) {
				$out_bytes = $1;
				$pcount++;	
				next;
			} 
			if (/ifOperStatus.*up/i) {
				$if_status = 1;
				next;
			}
			if (/ifLastChange.*Timeticks: \(\d+\)/) {
				# Depending on what's being queried, uptime may
				# not be present.  The solution is to do all the
				# formatting of it here, and just include it in the
				# final output.  If it's not present, this will never
				# execute and $if_uptime will be undefined
				s/.*Timeticks: \(\d+\) //;
				$if_uptime = sprintf('(Uptime:%s)',$_);
				next;
			}
		}
		my $status = close(CMD);
		$status >>= 8;
		if ($status != 0) {
			printf('Connection timed out querying interface on %s',$config{interface});
			exit 3;
		} else {
			if ($if_status) {
				my ($output,$perfdata);
				my $output = sprintf('Interface %s is Up %s',$config{interface},$if_uptime);
				if ($pcount == 2) {
					$perfdata = sprintf('|in:%0.f out:%0.f',$in_bytes,$out_bytes);
				}
				print $output,$perfdata;
				exit 0;
			} else {
				printf('Interface %s is down',$config{interface});
				exit 2;
			}
		}
	}
}

sub findInterfaceIndex {
	# What this function does:
	# It's a two-step process to query an interface.  Each interface may have a name
	# on the switch, such as Gi3/0/1 or Po1, but both switches and firewalls
	# assign each interface an index.  Each class of device assigns indexes
	# according to its own rules.  So, there's two mib trees where this information
	# could be stored (the mapping of Interface Name -> Index number).  It could be in
	# one of the following trees:
	#
	# IF-MIB::ifName (Cisco switches use this one)
	# IF-MIB::ifDescr (Cisco PIX and ASA firewalls use this one)
	# So, there's a couple of strategies for how to know which to use.  One is 
	# to brute force it and query both ways and see if you find the index, the
	# other is to know beforehand and use a config file directive.  Config files
	# are preferrable to brute forcing it -- though it does require more research
	# up front to figure out which MIB tree your device requires.
		
	#print "Looking for $mib_to_query ($config{interface})\n";
	my $result = open(CMD,"$snmpwalk -v $version -c $community $args{I} $mib_to_query 2>&1|");
	if (!$result) {
		printf('Unable to run %s:%s',$snmpwalk,$!);
		exit 3;
	} else {
		while(<CMD>) {
			chomp;
			if (/$mib_to_query\.(\d+).*STRING:.*$config{interface}/) {
				$index = $1;
				last;
			}
		}
		my $status = close(CMD);
		$status >>= 8;
		if ($status != 0) {
			printf('Connection timed out finding interface on %s',$config{interface});
			exit 3;
		}
	}
	if (!$index) {
		printf('Unable to find Interface %s',$config{interface});
		exit 3;
	}
}

sub readThresholds {
	# This function is for reading the thresholds in.  Should return unknown under the following circumstances:
	# 1) file can't be found
	# 2) After reading the entire file, no valid entries can be found
	# The suffix for this script is dynamic, unlike the other versions of the same.  Therefore define suffix from args here.
	$suffix = $args{S};
	# Now that suffix has been defined, change all the spaces in it to underscores
	$suffix =~ s/\s/_/g;
	my $result = open(FILE,"$basedir/$args{C}/$args{H}-$suffix");
	my $arg_count = 0;
	if ($result) {
		while(<FILE>) {
			chomp;
			next if /^#/;
			if (/^interface:(.*)/) {
				$config{interface} = $1;
				$arg_count++;
				next;
			}
			if (/^community:(.*)/) {
				$community = $1;
				next;
			}
			# Valid versions are 1 and 2c
			if (/^version:(1|2c)/) {
				$version = $1;
				next;
			}
			if (/^counter:64/) {
				# Use 64-bit counters
				$in = $in_64;
				$out = $out_64;
				next;
			}
			# Some devices don't increment their OIDs properly, which upsets snmpwalk.
			# adding a -Cc tells snmpwalk to ignore this, which wile potentially leading
			# to an infinite loop, allows us to query devices that are otherwise not 100%
			# SNMP-compliant.  So far known culprits are PIX firewalls.
			if (/^has_quicks:yes/) {
				$snmpwalk = $snmpwalk.' -Cc';
				next;
			}
			# For more details on this, see the comments
			# at the start of findInterfaceIndex.  This is
			# where we select which MIB tree to use based
			# on the type of device we are querying.
			if (/^config:(\w+)/) {
				if ($1 eq 'switch') {
					$mib_to_query = $mib_name;
					$arg_count++;
				} elsif ($1 eq 'pix') {
					$mib_to_query = $mib_desc;
					$arg_count++;
				} elsif ($1 eq 'asa') {
					$mib_to_query = $mib_desc;
					$arg_count++;
				} else {
					print 'Invalid config: directive';
					exit 3;
				}
			}
		}
		close(FILE);
		if ($arg_count != 2) {
			# Means no interface name was found
			print 'Interface name and config (switch,pix,asa..) are required arguments';
			exit 3;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		printf('%s/%s-%s not found',$args{C},$args{H},$suffix);
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
		' -H <hostname> -S "Service Name" -C <customer abbrev> -I <ip address>',
		"\n";
	exit 3;
}
