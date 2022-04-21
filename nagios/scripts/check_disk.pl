#!/usr/bin/perl

use strict;

# Globals
my %partitions;
my $filename = 'partitions.txt';
my $cmd = 'check_disk';
# End Globals

# Main
checkBinary();
getPartitions();
checkPartitions();
# End Main

# Functions
sub checkBinary {
	# If you need comments for what this does, then stop reading
	if (!(-e $cmd)) {
		print "UNKNOWN: $cmd not found";
		exit 3;
	}
}

sub getPartitions {
	if (-e $filename) {
		# Read in partitions to check
		open(INPUT,$filename); 
		if (!($?)) {	# If there were NOT any errors ($?) continue
			while(<INPUT>) {
				chomp; # have to strip out the newline (\n) or split() doesn't work
				next if /^#/; # Allow for comments
				my @line = split();
				# Validate input file
				if (scalar(@line) != 3) { # must be 3 args per line
					next;
				}
				# Each line must have the following: <partition> <warning int> <critical int>
				if ($line[1] =~ /^\d{1,2}$/ && $line[2] =~ /^\d{1,2}$/) {
					# [] is notation for an anonymous array ref.
					# Make an array with line[1] and line[2] in it,
					# store in hash table where key = partition name, value = array ref of warn/crit thresholds
					$partitions{$line[0]} = [$line[1],$line[2]];
				}
			}
			close(INPUT);
		} else {
			# If we couldn't open the file, abort with error
			print "UNKNOWN: $?";
			exit 3;
		}
	} else {
		# If partition file doesn't exist, abort here too
		print "UNKNOWN: $filename not found";
		exit 3;
	}
}

sub checkPartitions {
	# First need to make sure we actually have some partitions to check
	if (scalar(keys(%partitions)) < 1) {
		print "UNKNOWN: No partitions configured to be checked";
		exit 3;
	}
	# Set some of the base args for check_disk
	my $cmdargs = '-t 5 -e ';
	# Now build the entire command line to exec by going over all the partitions in the hash
	while (my ($partition,$thresholds) = each(%partitions)) {
		# safety check: $thresholds must be an array ref
		next if ref($thresholds) ne 'ARRAY';
		# the @$ notation is because this is an array REFERENCE
		# concatenate this partition and its thresholds to our mega-string
		$cmdargs.= "-w @$thresholds[0]\% -c @$thresholds[1]\% -p $partition -C ";
	}
	# Now we've built the command string, execute it with all the arguments we just made
	open(CMD,"./$cmd $cmdargs|") || die "ERROR: $!";
	# Give me the output please
	while(<CMD>) {
		print $_;
	}
	close(CMD);
	# I am not sure why you have to do this to get the exit code of a child process of the perl
	# interpreter, but you have to take the exit code ($?) and right-shift it by 8 (binary shift)
	# if that makes no sense, just accept that it works.  (If it does make sense and you know why it's required,
	# let Jake know please!
	exit $? >> 8;
}
# End Functions
