package CheckBySSH;

#########################################################
#
# Purpose: Framework for checking a service via SSH
# Author:  Jake Kruse
# Date: 11/13/2007
# Revision History:
#	11/13/07 - Takes a user argument on queryHost
#	Oct/07 	 - Uses IO::Select instead of eval/die
#		   for invoking SSH and catching errors	
#       Sep/07   - Initial Release
#
#########################################################


use strict;
use IO::Select;

# Some notes on the command-line arguments passed to SSH
# PasswordAuthentication=no: if the remote server does not have public key authentication setup correctly,
#       SSH will prompt for a password.  This breaks SSH-based monitoring.  By disabling password authentication,
#       the SSH client will send an error to STDERR.
# StrictHostKeyChecking=yes: we do not want SSH to even prompt to store the public key of the remote host, as again
#       this would break the behaviour of this script.  By having SSH reject keys it does not have in known_hosts,
#       errors go to STDERR.
# By having SSH just give up rather than prompt in either case, we can redirect STDERR to STDOUT, and parse that output
# This gives us a lot more control over how SSH behaves


my $ssh = '/usr/bin/ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=yes'; # Full path to SSH client
our %query_results; # Needs to 'our' to be visible outside of this module


sub queryHost {
	my ($cmd,$ip,$timeout,$user) = @_;
	die 'No Command Specified!' if !$cmd;
	# If a user has been specified, use the supplied username.  Otherwise,
	# use the default (nagios)
	if (!defined($user)) {
		$user = 'nagios';
	}
	my ($pid,$exit_code,@cmd_output);
	my $command = "$ssh $user\@$ip $cmd 2>&1";
	#my $command = "$ssh $ip /u01/app/nagios/libexec/sleep1.pl 2>&1"; # Testing override
	#print $command,"\n";
	$pid = open(CMD,"$command|");
	if ($pid) {
		# Why are we using IO::Select instead of a standard eval/die pair with alarm()?  Alarm is great under most circumstances,
		# but signals are not re-entrant; only one process gets to play with any given signal at a time.  Anything else
		# attempting to invoke the same signal just blocks for a very long time, and you end up with a giant queue of processes
		# that have to wait *before* they can invoke alarm and have their timeout.  For monitoring this sucks in a big way, hundreds
		# of processes can get logjammed at once all waiting for their turn on the alarm signal.  Select/Poll does not have this limitation.
		# The IO::Select makes handling the select() function much easier as well, since it handles all the bitmasks and junk for us.
		#
		# So how does IO::Select accomplish the same?  Basically we create the object, add our command to its list of handles
		# that need to be polled, and give it $timeout seconds to read from said handle.  Note that we don't bother closing
		# the handle; after IO::Select has worked on it we can't get the status code back from it anyway (which is the only 
		# reason we are interested in closing it!)
		my $s = IO::Select->new();
		$s->add(\*CMD);
		# can_read() returns an array of handles that can be read from.  We are only interested in the count
		# so we look at the arrays purely in a scalar context
		my $cnt = $s->can_read($timeout); 
		if ($cnt >  0) {
			my ($input,$data);
			# Not fully sure why, but using IO::Select calls and buffered I/O (i.e <CMD>
			# type operators) causes unpredictable results.  So use sysread instead
			# and then split() later on (if CMD closes OK)  to convert to what <CMD> would have returned
			# This may not be the case given how IO::Select is used in this context, but it's easy enough
			# to do via sysread() to be on the safe side.
			while (sysread(CMD,$input,1024)) {
				$data.= $input;
			}
			if (length($data) > 0) {
				# We have output, test to see if it's valid or not
				if ($data =~ /Host key verification failed/) {
					$query_results{output} = 'Unknown SSH Key';
					$query_results{status_code} = 3;
				} elsif ($data =~ /Permission denied/) {
					$query_results{output} = 'SSH Permission Denied';
					$query_results{status_code} = 3;
				} elsif ($data =~ /No route to host/) {
					$query_results{output} = 'Connection Timed Out';
					$query_results{status_code} = 3;
				} else {
					# Our output does not contain any errors that at least we know of so far
					# Stick the cmd_output array into query_results	
					# Do not set status_code
					@cmd_output = split(/\n/,$data);
					$query_results{output} = \@cmd_output;
				}
			} else {
				# This means that for whatever reason no data came back from the host
				# Very strange and probably worth investigating when this case happens
				$query_results{output} = 'UNKNOWN: No Output From Host!';;
				$query_results{status_code} = 3;
				# SSH will block indefinetly whether we interact with it anymore or not
				# under circumstances where it just hangs.  Kill it
				kill(9,$pid);
			}
		} else {
			# The command timed out on the remote host.  It actually connected and ran it,
			# but for whatever reason it timed out.  This shouldn't happen under most
			# circumstances since the command that is run is usually as short as possible
			$query_results{output} = 'UNKNOWN: Command timed out on host';;
			$query_results{status_code} = 3;
			# Just like the case where SSH timed out on the remote host, we have to kill the
			# local SSH process started on our end.  Note that the command on the remote host will keep
			# running even though we've detached from it.
			kill(9,$pid);
		}
	} else {
		# The command failed to start, this is weird and should never happen
		$query_results{output} = 'UNKNOWN: Unable to run command: contact SA Team';
		$query_results{status_code} = 3;
	}
}

1;
