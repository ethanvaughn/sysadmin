#!/usr/bin/perl

#####################################################################################################################
#
# Purpose: 	Checks to see if the server can, using SQL*Plus, establish a connection to its DB server
#		Assumes a valid tnsnames.ora exists, all environment variables are setup properly, etc.
#		Also requires that ssh_user have public-key auth setup for this monitoring server.  (Thus if
#		this is running as the tomax user, tomax user must have this monitoring server's public
#		key for the nagios user -- same as otranpost)
#
# $Id: check_remote_sqlplus.pl,v 1.1 2008/04/26 17:58:06 jkruse Exp $
# $Date: 2008/04/26 17:58:06 $
#
#####################################################################################################################

use lib '/u01/app/nagios/libexec/lib';

use strict;
use ArgParse;
use CheckBySSH;

# Globals and configuration vars
my %args; 		# Where command-line arguments get stored
my $suffix; 		# Determined on the fly
my $cmd; 		# This will be built later
my $optstr = 		'I:H:C:S:t:';
my $basedir = 		'/u01/home/nagios/monitoring';
my $usage = 		'-H <hostname> -C <customer abbrev> -I <ip address> -t <timeout in seconds> -S "Service Name"',

# Output variables
my ($output,$return_code);

# Function-specific variables
my %config;

# Main Body
ArgParse::getArgs($optstr,5,\%args,\$usage);
readThresholds();
CheckBySSH::queryHost($cmd,$args{I},$args{t},$config{ssh_user});
parseOutput();

sub parseOutput {
	if (exists($CheckBySSH::query_results{status_code})) {
		# Means the command timed out or the connection was refused, etc. etc. etc.
		$output = $CheckBySSH::query_results{output};
		$return_code = $CheckBySSH::query_results{status_code};
	} elsif (exists($CheckBySSH::query_results{cmd_exit_code})) {
		# We got an exit code back from CheckBySSH
		if ($CheckBySSH::query_results{cmd_exit_code} == 0) {
			# It exited OK
			$output = sprintf('SQL*Plus connected successfully to SID %s as user %s',$config{oracle_sid},$config{oracle_user});
			$return_code = 0;
		} else {
			# Non-Zero exit codes mean SQL*Plus returned an error, this will be in $query_results{output}
			foreach my $line (@{$CheckBySSH::query_results{output}}) {
				if ($line =~ /^ORA/) {
					$output = $line;
					last;
				}
			}
			if (!$output) {
				$output = sprintf('Unknown SQL*Plus error in connecting to SID %s as user %s',$config{oracle_sid},$config{oracle_user});
			}
			$return_code = 2;
		}
	} else {
		# This means we can't determine the output
		$output = 'Unable to determine status from SQL*Plus';
		$return_code = 3;
	}
	print $output;
	exit $return_code;
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
			if (/(ssh|oracle)_user:(.*)/) {
				$config{$1.'_user'} = $2;
				$arg_count++;
				next;
			}
			if (/env_source:(.*)/) {
				$config{env_source} = $1;
				$arg_count++;
				next;
			}
			if (/oracle_password:(.*)/) {
				$config{oracle_password} = $1;
				$arg_count++;
				next;
			}
			if (/oracle_sid:(.*)/) {
				$config{oracle_sid} = $1;
				$arg_count++;
				next;
			}
		}
		close(FILE);
		if ($arg_count != 5) {
			# This means we didn't get any valid partitions to check
			print 'ssh_user,oracle_user,oracle_password,oracle_sid,env_course, are requred arguments';
			exit 3;
		} else {
			# All OK!
			# Build command before returning
			# Note that the pipe does not need to be escaped for some reason.  Perhaps
			# because of the quoting mania Perl ignores it? See check_remote_linux_file_count.pl,
			# where if the pipe was not escaped, Perl evaluated it.
			$cmd = sprintf
					(
					'"source %s;echo \"select \'active\' from dual\" | sqlplus -L -S \'%s/%s@%s\'"',
					$config{env_source},
					$config{oracle_user},
					$config{oracle_password},
					$config{oracle_sid}
					);
			return;
		}
	} else {
		# If result = undef, it means the file couldn't be found
		print $args{C},'/',$args{H},'-',$suffix,' not found';
		exit 3;
	}
}
