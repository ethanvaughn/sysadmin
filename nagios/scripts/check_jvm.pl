#!/usr/bin/perl

use strict;
use Socket;
use Getopt::Long;
use Net::SMTP;

my $smtpserver = '10.24.74.9';

my ($hostname,$host,$port,$uri);
GetOptions('N=s' => \$hostname,'H=s' => \$host,'P=i' => \$port,'U=s' => \$uri);

if (!$hostname || !$host || !$port || !$uri) {
	print "Usage: $0 -N <hostname to match> -H <host/IP to query> -P <port> -U <url>\n";
	exit 2;
}

my (%hosts,$counter,$exit,@messages);
my $basemsgstr = 'CMD: PROCESS_SERVICE_CHECK_RESULT;'.lc($hostname).';';
until (exists($hosts{$hostname}) || $counter == 5) {
	queryHost();
	$counter++;
}

prepareMessage();
sendMessage();

sub sendMessage {
	my $smtp = Net::SMTP->new($smtpserver) || die $?;
	$smtp->mail("active_connections\@$hostname");
	$smtp->to('passivecheck@localhost');
	$smtp->data();
	foreach my $message(@messages) {
		$smtp->datasend($message);
	}
	$smtp->dataend();
	$smtp->quit();
}

sub prepareMessage {
	# Now we need to see if we have received any data for this host in question
	if (exists($hosts{$hostname})) {
		push(@messages,$basemsgstr."J2EE Status;0;OK: Service Responding\n");
		# That's one.  Now set DB connectivity status
		if (exists($hosts{$hostname}->{response})) {
			if ($hosts{$hostname}->{response} == 200) {
				# Means everything is good, set connection performance time
				push(@messages,$basemsgstr."DB Connection Status;0;OK: Successfully Connected to DB\n");
				# Now calculate the response time
				my $response_time = $hosts{$hostname}->{conntime} + $hosts{$hostname}->{querytime};
				push(@messages,$basemsgstr."DB Response Time;0;OK: Response Time: $response_time ms|$response_time\n");
			} else {
				# There is no connection to the DB
				push(@messages,$basemsgstr."DB Connection Status;2;CRITICAL: Unable to Connect to DB\n");
				push(@messages,$basemsgstr."DB Response Time;2;CRITAL: Connection Timed Out\n");
			}
			# JVM stuff is always present, so set that here
			my $freemem_bytes = $hosts{$hostname}->{freemem}; # Easier to store it in a var
				my $freemem;
			if ($freemem_bytes >= 1048576) {
				$freemem = int($freemem_bytes/1048576).' MB';
			} else {
				$freemem = int($freemem_bytes/1024).' KB';
			}
			my $freemem_mb = int($freemem_bytes/1048576); # Display it in MB
				push(@messages,$basemsgstr."JVM Free Memory;0;OK: Memory Free: $freemem|$freemem_bytes\n");
		} else {
			# We've got weird stuff here and can't proceed processing
			# if a status code wasn't set
			return;
		}
	} else {
		push(@messages,$basemsgstr."J2EE Status;2;CRITICAL: No data received\n");
	}
}

sub queryHost {
	my $proto = getprotobyname('tcp');
	# Initial socket setup.  Note the classic eval() to implement a timeout
	socket (FH, PF_INET, SOCK_STREAM, $proto) || die "socket: $!";
	my $sin = sockaddr_in($port, inet_aton($host));
	my $timeout = 15; # Time in seconds
		eval {
			local $SIG{ALRM} = sub { die 'timeout' };
			alarm($timeout);
			connect(FH, $sin) || die "connect: $!";
			alarm(0);
		};

	# Errors that are unlikely to happen but we better catch them anyway
	# In the event any of these occur, there's really nothing we can do except exit
	if ($@ =~ /^timeout/) {
		die "Connection timed out";
	} elsif ($@ =~ /Connection refused/) {
		die "Connection refused";
	} elsif ($@) {
		die "Internal error: $@";
	}

	my $rc = send(FH, "GET $uri HTTP/1.0\r\n\r\n", 0);
	unless (defined($rc)) {
	# If we can't connect there's really not a whole lot to do here.  Other services
	# will tag this service as down without worrying about it here
		die "Send error: $!";
	}
	my ($rin,$rout,$rbuf);
	vec($rin, fileno(FH), 1) = 1;
	# Lots of socket hooey
	if (select($rout=$rin, undef, undef, $timeout)) {
		my ($hostname,%data); # Our data structures used to parse the response back with
			# Not sure what goes in addr, but 10000 is the MAXIMUM number of bytes to read back
			my $addr = recv(FH, $rbuf, 10000 , 0);
		# $rbuf contains one giant blob of text.  Separate by newlines for better control
		my @lines = split(/\n/,$rbuf);
		foreach my $line (@lines) {
			if ($line =~ /response/) {
				# This line has the goods (separated by ^s)
				my @data = split(/\^/,$line);
				foreach my $token (@data) {
					# Each key/value pair is = separated
					my @keyval = split(/=/,$token);
					# We need to treat hostname special, since it will be the key of our base hash
					# (we also have to regex off the FQDN)
					if ($keyval[0] eq 'hostname') {
						$keyval[1] =~ s/\..*$//;
						$hostname = $keyval[1];
					} else {
						$data{$keyval[0]} = $keyval[1];
					}
				}
				# Better to be safe than sorry here.  Maybe hostname didn't get returned or something
				# If we just assumed it worked, this would cause a runtime error as a null key can't be
				# inserted into a hash
				if (defined($hostname)) {
					# Here we use hostname (set above) as the key of the %hosts hash, which points to %data,
					# our values hash (response code, freemem, conntime, etc.)
					$hosts{$hostname} = \%data; 
					last; # Nothing more to see here, move along
				}
			}
		}
	}
	close(FH) or die "FH close error: $!"; 
}

