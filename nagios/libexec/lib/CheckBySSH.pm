package CheckBySSH;

########################################################################
#
# Purpose: Framework for checking a service via SSH
#
# $Id: CheckBySSH.pm,v 1.8 2009/06/02 18:21:25 evaughn Exp $
# $Date: 2009/06/02 18:21:25 $
#
########################################################################


use strict;
use IPC::Open3;

# Some notes on the command-line arguments passed to SSH
# PasswordAuthentication=no: if the remote server does not have public key authentication setup correctly,
#       SSH will prompt for a password.  This breaks SSH-based monitoring.  By disabling password authentication,
#       the SSH client will send an error to STDERR.
# StrictHostKeyChecking=yes: we do not want SSH to even prompt to store the public key of the remote host, as again
#       this would break the behaviour of this script.  By having SSH reject keys it does not have in known_hosts,
#       errors go to STDERR.
# By having SSH just give up rather than prompt in either case, we can redirect STDERR to STDOUT, and parse that output
# This gives us a lot more control over how SSH behaves
# ConnectTimeout=<given value>: This is yet another layer of timeouts used to keep SSH from hanging.  This only
#	affects the initial connection -- SSH will wait up to <given value> seconds before giving up.  Only
# 	applies to connection timeouts, not connect refused, or after the connection has been established.
#	The timeout is set to $timeout-1 seconds


my $ssh = '/usr/bin/ssh'; # Full path to SSH client
our %query_results; # Needs to 'our' to be visible outside of this module


sub queryHost {
	my $cmd     = shift;
	my $ip      = shift;
	my $timeout = shift;
	my $user    = shift;

	die 'No Command Specified!' if !$cmd;
	# If a user has been specified, use the supplied username.  Otherwise,
	# use the default (nagios)
	if (!defined($user)) {
		$user = 'nagios';
	}

	my $pid;
	my $exit_code;
	my @cmd_output;
	my $reader;
	my $writer;

	my $ssh_opts = '-o PasswordAuthentication=no -o StrictHostKeyChecking=yes -o ConnectTimeout=' . ($timeout - 1); # Options to pass to client
	my $command = sprintf( '%s %s %s@%s %s', $ssh, $ssh_opts, $user, $ip, $cmd );

#print STDERR $command . "\n";

	# Use $reader for both STDOUT and STDERR -- we never use $writer, but it
	# can't be left empty.
	$pid = open3( $writer, $reader, $reader, $command );
	if ($pid) {
		my ($rin,$rout);
		my ($input,$data);
		vec($rin, fileno($reader), 1) = 1;
		# The purpose of this loop is to only read on the filehandle when there
		# actually exists something to read.  select() provides this functionality
		# and prevents us from blocking on reads, since sysread is only called
		# after select() indicates that there is data on the filehandle to read
		my $i; # Give $i scope outside the loop since we will look at it later
		for ($i = 0; $i < $timeout; $i++) {
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
		if ($i == $timeout) {
			# Note that we don't care if we have partial output from the command --
			# if it timed out, it timed out, and that's the error that needs
			# to be raised.  There is a chance SOME output is in $data, but 
			# there's also a good chance that not ALL of it is there, in which
			# case it is useless anyway.  It's either all or nothing!
			kill(9,$pid);
			$query_results{output} = 'Command timed out on host';;
			$query_results{status_code} = 3;
		} else {
			# The command did not timeout, which means it will also exit normally
			# If $data has stuff in it, check for common SSH errors.  Otherwise,
			# just grab exit code close the handle.  Under some circumstances,
			# it could be perfectly normal for the remote command to return
			# nothing at all.
			if (length($data) > 0) {
				if ($data =~ /Host key verification failed/) {
					$query_results{output} = 'Unknown SSH Key';
					$query_results{status_code} = 3;
				} elsif ($data =~ /^Permission denied/) {
					$query_results{output} = 'SSH Permission Denied';
					$query_results{status_code} = 3;
				} elsif ($data =~ /No route to host/ || $data =~ /Connection timed out/) {
					$query_results{output} = 'Connection Timed Out';
					$query_results{status_code} = 3;
				} else {
					# Our output does not contain any errors that at least we know of so far
					# Stick the cmd_output array into query_results	
					# Do not set status_code
					@cmd_output = split(/\n/,$data);
					$query_results{output} = \@cmd_output;
				}
			}
			# Close out all handles and call waitpid.  Unlike a standard open() call,
			# just closing the filehandles used by open3() will not make the exit
			# code of the remote executable available -- only calling waitpid() will do this
			close($reader);
			close($writer);
			waitpid($pid,0);
			my $cmd_exit = $?;
			$cmd_exit >>= 8;
			$query_results{cmd_exit_code} = $cmd_exit;
		}
	} else {
		# The command failed to start, this is weird and should never happen
		$query_results{output} = 'Unable to run command: contact SA Team';
		$query_results{status_code} = 3;
	}
}

1;
