package PassiveCMD;

###################################################################################################################
#
# Purpose:	Submits passive commands to the Nagios FIFO.  Some active checks also need to be able to
#		submit commands to Nagios in addition to the standard output/return code.  This module
#		provides everything necessary to do this safely (file locking on the FIFO, etc.)
#
# $Id: PassiveCMD.pm,v 1.1 2008/05/02 01:13:18 jkruse Exp $
# $Date: 2008/05/02 01:13:18 $
#
###################################################################################################################

use Fcntl ':flock';	

my $fifo = '/u01/app/nagios/var/rw/nagios.cmd'; # Location of the Nagios named pipe (FIFO)

sub submit {
	my $cmd = shift;
	my $check = sprintf('[%lu] %s%s',time(),$cmd,"\n");
	eval {
		local $SIG{ALRM} = sub { die 'timeout' };
		alarm(5);
		open(FH,'>'.$fifo) || die $!;
		# FIFOs on Linux can't hold a lot of data.  To keep from overloading the FIFO, we do
		# an exlcusive lock so that the other processes writing to this FIFO will have to queue up
		# so as to prevent buffer overflows.  (Which are very easy to cause with FIFOs!)
		flock(FH,LOCK_EX) || die $!;
		syswrite(FH,$check);
		flock(FH,LOCK_UN);
		close(FH);
		# Diagnostics during testing
		#print $check;
		alarm(0);
	};
	# If there were any errors in submitting the command (file not found, timeout, failed to lock)
	# return false + error code.  Otherwise, return true
	if ($@) {
		return 0,$@;
	} else {
		return 1;
	}
}

1;
