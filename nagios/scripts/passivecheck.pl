#!/usr/bin/perl
use strict;

# Globals
my @cmds;
my $nagios = '/u01/app/nagios/var/rw/nagios.cmd';

readInput();
sendCMDs();

sub readInput {
        my $timeout = 3; # How long to wait before giving up
        eval {
                local $SIG{ALRM}=sub { die "timeout"; };
                alarm $timeout;
                while(<STDIN>) {
			if (/^CMD:\s/) {
				chomp;
				s/^CMD:\s//;
				s/'//g; # Single-quotes horribly break certain other ticketing systems
				push(@cmds,$_);
			}
                }
                alarm 0;
        };
	if (scalar(@cmds) == 0) {
		# If no commands were found (because of a parse error, whatever, this will give us a nice viewable
		# error in the maillog
		die "No commands found to submit"; 
	}
}

sub sendCMDs {
	# First make sure the named pipe actually exists.  Perl will create it , if it doesn't, which is not what we want
	# Nagios is in charge of creating the pipe, so this basically checks to see if Nagios is running or not
	if (!(-e $nagios)) {
		die "$nagios does not exist!";
	}
	# Print out all the CMDs to the named pipe.  Make sure and use append mode so that perl
	# doesn't attempt to overwrite the pipe.  
	open(CMD,">>$nagios") || die "Unable to open $nagios: $!";
	foreach my $cmd (@cmds) {
		printf CMD ("[%lu] $cmd\n",time());
	}
	close(CMD);
}
