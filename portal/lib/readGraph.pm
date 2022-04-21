#!/usr/bin/perl

package lib::readGraph;
use strict;
use Socket;

sub readURL {
	my ($host,$url) = @_;
	# Create socket
	socket(FH,PF_INET,SOCK_STREAM,getprotobyname('tcp')) || die $!;
	my $sin = sockaddr_in(80,inet_aton($host));
	my $timeout = 5; # Configure the timout here
	my $data; # Where the remote server's response is stored
	eval {
		local $SIG{ALRM} = sub { die 'timeout' };
		alarm($timeout);
		connect(FH, $sin) || die "connect: $!";
		# Ye old socket now connected, send GET request
		send(FH, "GET $url HTTP/1.0\r\n\r\n", 0);
		
		my $buffer = 1; # As the name implies, the buffer to hold each chunk as it is read back
		while($buffer) {
			recv(FH,$buffer,2048,0); # Read 2K chunks
			$data.= $buffer; # And append what was read to $data
		}
		close(FH) || die $!;
		alarm(0);
	};
	# Before moving on to parsing the server's response, check for errors
	# Some helpful error messages could be sent back to the browser here, die isn't all that user friendly
	if ($@) {
		print "Refresh: 60\n";
		print "Content-type: text/html\n\n";
		print "<p>Retrieving data from servers...please be patient as data is loaded.</p>";
		print "<p>The page will automatically refresh in 1 minute.</p>";
		exit;
	} else {
		# In order to send this back to the browswer, we need the original content-type and everything
		# up to the trailing newline in the header
		if ($data =~ /([C-c]ontent-[T-t]ype:.*((\r|\n)\n){2})/) { # Match both \r\n and \n\n
			#print $1; # Reprints the original header
			# Everything after $1 is the document (actual data, text or binary) to be returned
			# The ending character index of the matching regex for $1 is stored in $+[0]
			# Thus print everything immediately after $1 to EOF
			#print substr($data,$+[0]); 
			# Instead of making two calls to print(), do just one starting at ^Content-....
			# and print to EOL
			print substr($data,$-[0]);
		}
	}
}

1;
