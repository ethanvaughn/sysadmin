#!/usr/bin/perl

use lib '/u01/app/nagios/scripts'; # Used to include HostToGroup (when this script is called by postfix)

use strict;
use Net::SMTP;
use HostToGroup; # Maps hostnames
use Fcntl ':flock'; # import LOCK_* constants

# Imported Variables
$cfgfile = '/u01/app/nagios/etc/hostgroups.cfg';

# Globals

# @input: where all received commands are stored
# @cmds: where all Nagios commands are stored
my (@input,@cmds);
my $sending_host; # The host the commands are coming *from*
my ($optional_recipient,$message,$subject,$customer);
my $nagios = '/u01/app/nagios/var/rw/nagios.cmd'; # Location of named pipe (FIFO) for Nagios
my $downtime = '/u01/app/nagios/var/downtime.dat'; # Location where scheduled downtime in Nagios is stored

readInput();
parseCMDs();
sendCMDs();

# readInput(): reads the message off of STDIN, and stores all submitted CMDs in @input
sub readInput {
        my $timeout = 3; # How long to wait before giving up
        eval {
                local $SIG{ALRM}=sub { die "timeout"; };
                alarm $timeout;
                while(<STDIN>) {
			chomp;
			# Each line that contains a valid CMD will start with MAINT:
			# This removes that prefix and adds it to @input for further processing
			if (/^NOTIFY:/) {
				s/^NOTIFY://;
				$optional_recipient = $_;
				next;
			}
			if (/^MAINT:/) {
				s/^MAINT://;
				push(@input,$_);
				next;
			}
			if (/^From:/) {
				# The below two regexs are to get just the hostname stored in $sending_host
				s/^From:\s+.*\@//; # Remove everything up to the @ sign
				s/\..*$//; # Remove everything from the first . to EOL
				$sending_host = $_;
				next;
			}
                }
                alarm 0;
        };
	if (scalar(@input) == 0 || !$sending_host) {
		# If no commands were found (because of a parse error, whatever, this will give us a nice viewable
		# error in the maillog
		die 'No maintenance commands found to submit, or sending host not identifed properly'; 
	}
}

# parseCMDs(): 	processes the list of submitted commands stored in @input, checks validity of each,
# 		and builds the appropriate commands to submit to Nagios
sub parseCMDs {
	# 1st iterate over all CMDs in @input and parse each one
	foreach (@input) {
		my @line = split(/_/); # All commands must be delimited by underscores
		# Now validate the command
		if ($line[0] eq 'add') {
			if ($line[1] eq 'hs' && scalar(@line) == 4) {
				next if !validateHost($line[2]);
				push(@cmds,generateStartWindowCMD(1,$line[2],$line[3]));
			} elsif ($line[1] eq 'h' && scalar(@line) == 3) {
				next if !validateHost($line[2]);
				push(@cmds,generateStartWindowCMD(2,$line[2]));
			} elsif ($line[1] eq 'hg' && scalar(@line) == 3) {
				next if !validateGroup($line[2]);
				push(@cmds,generateStartWindowCMD(3,$line[2]));
			} else {
				# Invalid format...
				next; # Must be a service (hs), host (h), or host group (hg)
			}
		} elsif ($line[0] eq 'del') {
			if ($line[1] eq 'hs' && scalar(@line) == 4) {
				next if !validateHost($line[2]);
				generateStopWindowCMD(1,$line[2],$line[3]);
			} elsif ($line[1] eq 'h' && scalar(@line) == 3) {
				next if !validateHost($line[2]);
				generateStopWindowCMD(2,$line[2]);
			} elsif ($line[1] eq 'hg' && scalar(@line) == 3) {
				next if !validateGroup($line[2]);
				generateStopWindowCMD(3,$line[2]);
			}
		} else {
			next; # Not a valid command -- only add/del are valid keywords
		}
	}
}

# generateStopWindowCMD($mode,$obj,$svr): generates the right downtime deletion commands and adds
#					  them to @cmds.  Unlike generateStartWindowCMD, adds the commands
#					  directly to @cmds.  This is because for any given object,
#					  multiple commands could be required
sub generateStopWindowCMD {
	my ($mode,$obj,$svc) = @_;
	# First we need to read in all the current downtime entries
	my $downtime = readDowntimeFile();
	# Validate the hash ref came back properly
	die 'hash ref not returned by readDowntimeFile()' if ref($downtime) ne 'HASH';
	if ($mode == 1) {
		$customer = uc(mapHostToGroup($obj));
		while (my ($id,$vals) = each(%$downtime)) {
			if ($vals->{hostname} eq $obj && $vals->{service} eq $svc) {
				push(@cmds,"DEL_SVC_DOWNTIME;$id");
				$subject = "Maintenance Stopped: $obj - $svc ($customer)\n";
				$message = "Maintenance Window ended for Server $obj - $svc ($customer)\n";
				last; # Match just one host/service combination
			}
		}
	} elsif ($mode == 2) {
		while (my ($id,$vals) = each(%$downtime)) {
			if ($vals->{hostname} eq $obj) { # Match any entry for this host
				push(@cmds,"DEL_SVC_DOWNTIME;$id");
			}
		}
		if (defined(@cmds)) {
			$customer = uc(mapHostToGroup($obj));
			$subject = "Maintenance Stopped: $obj ($customer)\n";
			$message = "Maintenance Window ended for Server $obj ($customer)\n";
		}
	} elsif ($mode == 3) {
		# First cleanup $obj.  Say maintenance window for km-lab is being turned off.  km-lab isn't a
		# group HostToGroup reads (it's really Host->Customer) so it would fail here.  Instead what we do
		# is remove everything from the first dash to EOL.  This means some maintenance windows may all end
		# prematurely though.  (Since a command for km-prod would wipe out maintenance for km-lab, for example)
		# The solution to this would be to have HostToGroup read from the object cache (which
		# has all groups in it) instead of hostgroups.cfg
		$obj =~ s/-.*$//;
		while (my ($id,$vals) = each(%$downtime)) {
			# Match any entry for the entire customer
			if (mapHostToGroup($vals->{hostname}) eq $obj) {
				push(@cmds,"DEL_SVC_DOWNTIME;$id");
			}
		}
		if (defined(@cmds)) {
			$customer = uc($obj);
			$subject = "Maintenance Stopped: $customer\n";
			$message = "Maintenance Window ended for $customer\n";
		}
	} else {
		# Invalid mode, return and do nothing
		return; 
	}
}

sub readDowntimeFile {
	my ($file,%entries);
	open($file,$downtime) || die "Unable to open downtime file: $!";
	while(<$file>) {
		if (/^servicedowntime/) {
			my ($id,$entry) = readDowntimeEntry($file);
			if ($id && $entry) {
				$entries{$id} = $entry;
			}
		}
	}
	close($file);
	return \%entries;
}

sub readDowntimeEntry {
	my $fh = shift;
	my ($id,%entry);
	while(<$fh>) {
		chomp;
		if (/}/) {
			last;
		}
		if (/host_name=/) {
			s/^.*host_name=//;
			$entry{hostname} = $_;
			next;
		}
		if (/service_description=/) {
			s/^.*service_description=//;
			$entry{service} = $_;
			next;
		}
		if (/downtime_id=/) {
			s/^.*downtime_id=//;
			$id = $_;
			next;
		}
	}
	return $id,\%entry;
}

# generateStartWindowCMD($mode,$obj,$svc): returns a formatted downtime CMD that can be sent to nagios.
#					note that $svc is only required if $mode == 3 (specific service
#					on a single host)
sub generateStartWindowCMD {
	my ($mode,$obj,$svc) = @_; # Note $svc could be null.  $obj is either a host or host group
	my $start = time();
	my $end = getEndOfWindow();
	if ($mode == 1 && defined($svc)) {
		$customer = uc(mapHostToGroup($obj));
		$subject = "Maintenance Started: $obj - $svc ($customer)\n";
		$message = "Maintenance Window active for Server $obj ($customer) Service $svc\n";
		return "SCHEDULE_SVC_DOWNTIME;$obj;$svc;$start;$end;1;0;0;$sending_host;DBA Scheduled";
	} elsif ($mode == 2 && defined($obj)) {
		$customer = uc(mapHostToGroup($obj));
		$subject = "Maintenance Started: $obj ($customer)\n";
		$message = "Maintenance Window active for Server $obj ($customer)\n";
		return "SCHEDULE_HOST_SVC_DOWNTIME;$obj;$start;$end;1;0;0;$sending_host;DBA Scheduled";
	} elsif ($mode == 3 && defined($obj)) {
		$customer = uc($obj);
		$subject = "Maintenance Started: $customer\n";
		$message = "Maintenance Window active for Group $customer\n";
		return "SCHEDULE_HOSTGROUP_SVC_DOWNTIME;$obj;$start;$end;1;0;0;$sending_host;DBA Scheduled";
	} else {
		return undef;
	}
}

# validateHost($target_host):	validates that $target_host is in the same group as $sending_host
#				returns true if $target_host is part of the same group $sending_host	
sub validateHost {
	my $target_host = shift;
	my $target_group = mapHostToGroup($target_host); # Get the group of the host to schedule for
	my $sending_host_group = mapHostToGroup($sending_host); # Get the group of the server that sent this
	# mapHostToGroup will return undef if there is no match.  No need to check for it, just run the comparison
	if ($target_group eq $sending_host_group) {
		return 1;
	} else {
		return 0;
	}
}

# validateGroup($target_group): validates that $sending_host is part of $target_group
#				returns true if $sending_host is part of $target_group, false otherwise
sub validateGroup {
	my $target_group = shift;
	# First make sure the group given is valid.  Valid groups aren't just rat,bjm, etc. but are also
	# rat-prod, rat-preprod, rat-portal, etc.  It's important to remove anything from the - on to the end
	# of the string, since we are only interested in the top-level group
	$target_group =~ s/-.*$//;
	if (!isGroup($target_group)) {
		return 0;
	}
	# Now we know this group is valid.  Get the group $sending_host is from
	my $sending_host_group = mapHostToGroup($sending_host);
	# Now that we've chopped off any extra parts of the target group, it's safe to compare
	# $sending_host_group to $target_group
	if ($sending_host_group eq $target_group) {
		return 1;
	} else {
		return 0;
	}
}

# sendCMDs(): 	takes each command in @cmds and sends it to Nagios over its named pipe (FIFO) as
#		defined by $nagios (location of FIFO)	
sub sendCMDs {
	# First make sure the named pipe actually exists.  Perl will create it , if it doesn't, which is not what we want
	# Nagios is in charge of creating the pipe, so this basically checks to see if Nagios is running or not
	if (!(-e $nagios)) {
		die "$nagios does not exist!";
	}
	# Print out all the CMDs to the named pipe.  Make sure and use append mode so that perl
	# doesn't attempt to overwrite the pipe.  
	open(CMD,">>$nagios") || die "Unable to open $nagios: $!";
	flock(CMD,LOCK_EX) || die "Unable to lock: $!";
	foreach my $cmd (@cmds) {
		printf CMD ("[%lu] $cmd\n",time()); # Submits the command
		#print "$cmd\n"; # Debugging
	}
	flock(CMD,LOCK_UN);
	close(CMD);
	if (defined($subject) && defined($message)) {
		my $smtp = Net::SMTP->new('localhost',Timeout => 10) || exit 1;
		$smtp->mail('noreply@tomax.com');
		if (length($optional_recipient) > 0) {
			$smtp->to($optional_recipient,"dba-$customer-email\@localhost");
		} else {
			$smtp->to("dba-$customer-email\@localhost");
		}
		$smtp->data();
		$smtp->datasend("To: \"$customer DBAs\" <dba-$customer-email\@localhost>\n");
		$smtp->datasend("From: noreply\@tomax.com\n");
		$smtp->datasend("Subject: $subject\n");
		$smtp->datasend($message);
		$smtp->dataend();
		$smtp->quit();
	}
}


# getEndOfWindow(): returns when the requested maintenance window should end (either today, or tomorrow at 5:00 AM)
sub getEndOfWindow {
	# First we need to determine what hour of the day it is
	# If it's before 5:00 AM now, calculate time (unix epoch) of 5:00 AM TODAY
	# If it's after 5:00 AM now, calculate time (unix epoch) of 5:00 AM TOMORROW
	my @curtime = localtime(time());
	my $end; # time the maintenance window will end (in unix epoch)
	if ($curtime[2] < 5) {
	# Need to set the end of the maintenance window to 5:00 AM on the current date
		$end = `date +\%s -d 'today 5:00 AM'`;
	} else {
	# Need to set the end of the maintenance window to 5:00 AM TOMORROW
		$end = `date +\%s -d 'tomorrow 5:00 AM'`;
	}
	chomp($end);
	return $end; # Return UNIX epoch time
	# These are for debugging purposes
	#print "UNIX Epoch time: $end\n";
	#print "Friendly time: ".scalar(localtime($end))."\n";
}
