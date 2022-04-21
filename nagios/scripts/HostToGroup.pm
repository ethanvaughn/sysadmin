package HostToGroup;
use strict;
use Carp;
require Exporter;


our @ISA     = qw/ Exporter /;
our @EXPORT  = qw/ mapHostToGroup isGroup $cfgfile/;

our $cfgfile;
my %hosts;
my @groups;

# Public function (exported)
sub isGroup {
	my ($group) = @_;
	if (!(defined($group))) {
		croak 'A group must be supplied to isGroup($group)';
	}
	if (!(defined(@groups))) {
		readFile();
	}
	my $retval = 0;
	# Go over all the groups and see if we have a match.  Wonder if a hash is faster?
	foreach my $g (@groups) {
		if ($g eq $group) {
			$retval = 1;
			last;
		}
	}
	return $retval; # is 0 by default.  If there is a match in the foreach() it wil be 1 (true)
}

# Public function (exported)
sub mapHostToGroup {
	my ($host) = @_;
	if (!(defined($host))) {
		croak 'A hostname must be supplied to mapHostToGroup($host)';
	}
	# Read in cfg file if we haven't yet
	if (!(defined(%hosts))) {
		readFile();
	}
	# Now return the mapping (if there is one)
	if (exists($hosts{$host})) {
		return $hosts{$host};
	} else {
		return undef;
	}
}

# Private function
sub readFile {
	my $fh; # File handle of config file
	# Error checking
	if (!(defined($cfgfile))) {
		croak '$cfgfile must be defined first';
	}
	if (!(-e $cfgfile)) {
		croak "$cfgfile does not exist, or is not accessible (check permissions?)";
	}
	# Now read in the file
	open($fh,$cfgfile) || croak "Unable to open $cfgfile: $!";
	while(<$fh>) {
		if (/^define hostgroup{/) {
			# We've hit a hostgroup definition.  Hand off to other function that deals with each group
			processGroup($fh);
		}
	} 
	close($fh);
}

# Private function
sub processGroup {
	my $fh = shift;
	# Internal var (see below where used..)
	my $group;
	if (!(defined($fh))) {
		croak 'Internal error on parsing group, no filehandle passed to processGroup($fh)';
	}
	while(<$fh>) {
		chomp;
		if (/hostgroup_name/) {
			s/^.*hostgroup_name\s+//; # remove everything before the name
			s/\s+$//; #remove all trailing whitespace
			$group = $_; # We use this later on (in the hash) so we need to save it
			push (@groups,$group);
			next; # don't need to run any additional checks against this line of input, move to next
		}
		if (/members/) {
			s/^.*members\s+//;
			my @members = split(/,/);
			foreach my $member (@members) {
				$hosts{$member} = $group; # Ah ha! I said we'd use $group again...
			}
			# We are done with this group, bail out of loop
			last;
		}
	}
}

# Required! all modules must return true (means successful compilation)
1;
